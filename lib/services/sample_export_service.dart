import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'package:lashae_s_application/env.dart';

class SampleExportService {
  static final _uuid = const Uuid();
  
  // Edge function URLs
  static const String _redactUrl = 'https://gnskowrijoouemlptrvr.supabase.co/functions/v1/sv_redact';
  static const String _publishUrl = 'https://gnskowrijoouemlptrvr.supabase.co/functions/v1/sv_publish_sample';

  /// Export a recording as a public de-identified PDF sample
  /// 
  /// [recordingId] - ID of the recording to export
  /// [transcriptText] - Transcript text to redact and export
  /// [synthetic] - If true, use synthetic template text (zero-risk marketing assets)
  /// [vertical] - Context for redaction (health, legal, ops)
  /// 
  /// Returns: { publicUrl, manifestUrl } on success
  /// Throws: Exception with user-friendly message on failure
  Future<Map<String, String>> exportPublicSample({
    required String recordingId,
    required String transcriptText,
    bool synthetic = false,
    String vertical = 'health',
  }) async {
    try {
      // Check feature flag from config
      if (!Env.redactionEnabled) {
        throw Exception('PII redaction feature is not enabled');
      }

      // Generate idempotency key
      final idempotencyKey = _uuid.v4();

      // Get auth token
      final supabase = Supa.client;
      final session = supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('AUTHENTICATION_FAILED: Please sign in to export samples');
      }

      String redactedText;
      Map<String, dynamic> entitiesCountByType = {};
      bool usedPresidio = false;

      if (synthetic) {
        // Skip redaction, use synthetic template
        redactedText = transcriptText; // Will be replaced with template in publish
        entitiesCountByType = {'NAME': 1, 'EMAIL': 1, 'PHONE': 1, 'DATE': 1};
        usedPresidio = false;
      } else {
        // Step 1: Call sv_redact Edge Function
        final redactResponse = await _callRedactFunction(
          text: transcriptText,
          synthetic: false,
          vertical: vertical,
          token: session!.accessToken,
        );

        // Check if redaction was successful (no error field means success)
        if (redactResponse.containsKey('error') || redactResponse.containsKey('failure_code')) {
          throw Exception('Couldn\'t de-identify this sample. Nothing was published.');
        }

        redactedText = redactResponse['redactedText'];
        entitiesCountByType = redactResponse['entitiesCountByType'] ?? {};
        usedPresidio = redactResponse['usedPresidio'] ?? false;
      }

      // Step 2: Generate PDF locally (only if not server-side)
      Uint8List? pdfBytes;
      if (!Env.serverSidePdf) {
        pdfBytes = await _generatePDF(
          redactedText: redactedText,
          vertical: vertical,
        );
      }

      // Step 3: Call sv_publish_sample Edge Function
      final publishResponse = await _callPublishFunction(
        recordingId: recordingId,
        redactedText: redactedText,
        vertical: vertical,
        entitiesCountByType: entitiesCountByType,
        usedPresidio: usedPresidio,
        synthetic: synthetic,
        pdfBytes: pdfBytes,
        idempotencyKey: idempotencyKey,
        token: session!.accessToken,
      );

      // Check if publish was successful (no error field means success)
      if (publishResponse.containsKey('error') || publishResponse.containsKey('failure_code')) {
        throw Exception('Couldn\'t publish this sample. Nothing was created.');
      }

      return {
        'publicUrl': publishResponse['publicUrl'],
        'manifestUrl': publishResponse['manifestUrl'],
      };

    } catch (e) {
      // Parse failure code from response if available
      String failureCode = 'UNKNOWN';
      String userMessage = 'Couldn\'t de-identify this sample. Nothing was published.';
      
      try {
        final errorStr = e.toString();
        print('Full error: $errorStr');
        
        if (errorStr.contains(':')) {
          // Extract failure code from error message (format: "CODE: message")
          final parts = errorStr.split(':');
          if (parts.length > 1) {
            failureCode = parts[0].trim();
            print('Extracted failure code: $failureCode');
          }
        }
        
        // Check for specific error patterns
        if (errorStr.contains('Invalid JWT') || errorStr.contains('401')) {
          failureCode = 'AUTHENTICATION_FAILED';
        } else if (errorStr.contains('REDACTION_FAILED')) {
          failureCode = 'REDACTION_FAILED';
        } else if (errorStr.contains('PUBLISH_FAILED')) {
          failureCode = 'PUBLISH_FAILED';
        } else if (errorStr.contains('AUTHENTICATION_FAILED')) {
          failureCode = 'AUTHENTICATION_FAILED';
        }
      } catch (_) {
        // Ignore parsing errors
      }

      // Map failure codes to user-friendly messages
      switch (failureCode) {
        case 'SERVICE_ROLE_MISSING':
          userMessage = 'Server not configured to publish yet.';
          break;
        case 'PATH_RLS_DENIED':
        case 'STORAGE_WRITE_FORBIDDEN':
          userMessage = 'Server storage permissions blocked publishing.';
          break;
        case 'PDF_RENDER_ERROR':
          userMessage = 'Couldn\'t create the PDF. Please retry.';
          break;
        case 'REDACTION_413_INPUT_TOO_LARGE':
          userMessage = 'That note is too long to share. Export a shorter section.';
          break;
        case 'AUTHENTICATION_FAILED':
          userMessage = 'Please sign in to export samples. The export feature requires authentication.';
          break;
        default:
          if (e.toString().contains('Couldn\'t')) {
            userMessage = e.toString();
          } else {
            userMessage = 'Couldn\'t de-identify this sample. Code: $failureCode. Nothing was published.';
          }
      }

      // Log failure code for debugging
      print('Export failed with code: $failureCode');
      
      throw Exception(userMessage);
    }
  }

  /// Call sv_redact Edge Function
  Future<Map<String, dynamic>> _callRedactFunction({
    required String text,
    required bool synthetic,
    required String vertical,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse(_redactUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'text': text,
        'format': 'pdf',
        'context': { 'vertical': vertical },
        'featureFlag': true,
        'synthetic': synthetic,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        final failureCode = errorBody['failure_code'] ?? 'UNKNOWN';
        final detail = errorBody['detail'] ?? 'Unknown error';
        throw Exception('$failureCode: $detail');
      } catch (e) {
        // If body isn't JSON, show HTTP status
        throw Exception('REDACTION_FAILED: HTTP ${response.statusCode} - ${response.body}');
      }
    }

    final result = jsonDecode(response.body);
    return {
      'redactedText': result['redactedText'],
      'entitiesCountByType': result['entitiesCountByType'] ?? {},
      'usedPresidio': result['usedPresidio'] ?? false,
    };
  }

  /// Call sv_publish_sample Edge Function
  Future<Map<String, dynamic>> _callPublishFunction({
    required String recordingId,
    required String redactedText,
    required String vertical,
    required Map<String, dynamic> entitiesCountByType,
    required bool usedPresidio,
    required String idempotencyKey,
    required String token,
    bool synthetic = false,
    Uint8List? pdfBytes,
  }) async {
    final response = await http.post(
      Uri.parse(_publishUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Idempotency-Key': idempotencyKey,
      },
      body: jsonEncode({
        'recording_id': recordingId,
        'redacted_text': redactedText,
        'user_id': Supa.client.auth.currentUser?.id,
        'vertical': vertical,
        'entities_count_by_type': entitiesCountByType,
        'used_presidio': usedPresidio,
        'synthetic': synthetic,
        if (pdfBytes != null) 'pdfBytes': base64Encode(pdfBytes),
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        final failureCode = errorBody['failure_code'] ?? 'UNKNOWN';
        final requestId = errorBody['request_id'];
        if (requestId != null) {
          print('Export failed with request_id: $requestId');
        }
        throw Exception('$failureCode: ${errorBody['detail'] ?? 'Unknown error'}');
      } catch (e) {
        // If body isn't JSON, show HTTP status
        throw Exception('UNKNOWN: HTTP ${response.statusCode} - ${response.body}');
      }
    }

    final result = jsonDecode(response.body);
    return {
      'publicUrl': result['publicUrl'],
      'manifestUrl': result['manifestUrl'],
    };
  }

  /// Generate PDF with redacted text
  Future<Uint8List> _generatePDF({
    required String redactedText,
    required String vertical,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with watermark
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'De-identified sample — PII removed or generalized\nVertical: $vertical',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Redacted content
              pw.Expanded(
                child: pw.Text(
                  redactedText,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    lineSpacing: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Load config from assets
  Future<Map<String, dynamic>> _loadConfig() async {
    try {
      // Load from assets/config/env.json
      final configString = await rootBundle.loadString('assets/config/env.json');
      final config = jsonDecode(configString) as Map<String, dynamic>;
      return config;
    } catch (e) {
      return {
        'SVN_REDACTION_FEATURE_FLAG': false,
        'PRESIDIO_ANALYZER_URL': '',
        'PRESIDIO_ANONYMIZER_URL': '',
        'SVN_SERVER_SIDE_PDF': false,
      };
    }
  }
}
