import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; // AUTH-GATE: Added for navigation

import '../core/utils/preview_mode_detector.dart';
import './supabase_service.dart';
import './auth.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';
import '../app/routes/app_routes.dart'; // AUTH-GATE: Added for Routes.loginScreen

class SummaryBackendService {
  static SummaryBackendService? _instance;
  static SummaryBackendService get instance =>
      _instance ??= SummaryBackendService._();

  SummaryBackendService._();

  // AUTH-GATE: Helper method to validate JWT and redirect if needed
  String? _getValidJWT() {
    final jwt = Supa.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      Get.offAllNamed(Routes.login);
    }
    return jwt;
  }

  static const String _svSummarizeRunUrl =
      'https://gnskowrijoouemlptrvr.functions.supabase.co/sv_summarize_run';
  static const String _summarizeTranscriptUrl =
      'https://gnskowrijoouemlptrvr.functions.supabase.co/summarize-transcript';
  static const String _svSignAudioDownloadUrl =
      'https://gnskowrijoouemlptrvr.functions.supabase.co/sv_sign_audio_download';

  /// Fetch note run by ID
  Future<Map<String, dynamic>?> getNoteRun(String runId) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock get note run');
      return {
        'id': runId,
        'status': 'summarized',
        'audio_url':
            'https://preview-mock.supabase.co/storage/v1/object/public/recordings/preview-audio.webm',
        'transcript_text':
            'This is a preview mode transcript that demonstrates the Summary screen functionality. It contains sample speech-to-text results.',
        'summary_v1': {
          'title': 'Preview Meeting Summary',
          'tl_dr':
              'This is a preview mode summary showing key insights and discussion points.',
          'key_points': [
            'Preview mode demonstration',
            'Summary screen functionality',
            'State machine workflow'
          ],
          'action_items': [
            'Test the real implementation',
            'Configure Supabase properly',
            'Deploy to production'
          ]
        },
        'created_at':
            DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'updated_at':
            DateTime.now().subtract(Duration(minutes: 1)).toIso8601String(),
        'user_id': 'preview-user-id',
        'duration_s': 180,
        'schema_version': 1,
        'error_msg': null
      };
    }

    try {
      if (runId.isEmpty) {
        throw Exception('Cannot fetch note run with empty runId');
      }

      final client = Supa.client;
      final userId = await AuthX.requireUserId();
      final response = await client
          .from('note_runs')
          .select()
          .eq('id', runId)
          .eq('user_id', userId)
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching note run: $e');
      return null;
    }
  }

  /// Get run events for a specific run_id
  Future<List<Map<String, dynamic>>> getRunEvents(String runId) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock get run events');
      return [
        {
          'id': 1,
          'run_id': runId,
          'event': 'run_created',
          'details': {'status': 'initialized'},
          'created_at':
              DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
          'user_id': 'preview-user-id'
        },
        {
          'id': 2,
          'run_id': runId,
          'event': 'transcription_started',
          'details': {'status': 'processing'},
          'created_at':
              DateTime.now().subtract(Duration(minutes: 8)).toIso8601String(),
          'user_id': 'preview-user-id'
        },
        {
          'id': 3,
          'run_id': runId,
          'event': 'transcription_completed',
          'details': {'status': 'transcribed'},
          'created_at':
              DateTime.now().subtract(Duration(minutes: 6)).toIso8601String(),
          'user_id': 'preview-user-id'
        },
        {
          'id': 4,
          'run_id': runId,
          'event': 'summary_completed',
          'details': {'status': 'summarized'},
          'created_at':
              DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
          'user_id': 'preview-user-id'
        }
      ];
    }

    try {
      if (runId.isEmpty) {
        throw Exception('Cannot fetch run events with empty runId');
      }

      final client = Supa.client;
      final userId = await AuthX.requireUserId();
      final response = await client
          .from('run_events')
          .select()
          .eq('run_id', runId)
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching run events: $e');
      return [];
    }
  }

  /// Subscribe to real-time changes for run_events
  Stream<Map<String, dynamic>> subscribeToRunEvents(String runId) {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock run events subscription');
      return Stream.empty();
    }

    try {
      final client = Supa.client;
      return client
          .from('run_events')
          .stream(primaryKey: ['id'])
          .eq('run_id', runId)
          .map((data) => data.isNotEmpty
              ? Map<String, dynamic>.from(data.last)
              : <String, dynamic>{});
    } catch (e) {
      debugPrint('Error subscribing to run events: $e');
      return Stream.empty();
    }
  }

  /// Subscribe to real-time changes for note_runs
  Stream<Map<String, dynamic>> subscribeToNoteRun(String runId) {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock note run subscription');
      return Stream.empty();
    }

    try {
      final client = Supa.client;
      return client
          .from('note_runs')
          .stream(primaryKey: ['id'])
          .eq('id', runId)
          .map((data) => data.isNotEmpty
              ? Map<String, dynamic>.from(data.first)
              : <String, dynamic>{});
    } catch (e) {
      debugPrint('Error subscribing to note run: $e');
      return Stream.empty();
    }
  }

  /// Call sv_summarize_run edge function
  Future<Map<String, dynamic>?> callSummarizeRun(String runId) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock summarize run');
      return {
        'success': true,
        'summary': {
          'title': 'Preview Generated Summary',
          'tl_dr':
              'This is a preview mode summary generated from the transcript.',
          'key_points': [
            'Successfully processed audio',
            'Generated comprehensive transcript',
            'Created actionable summary'
          ],
          'action_items': [
            'Review the implementation',
            'Test with real audio files',
            'Deploy to production'
          ]
        }
      };
    }

    try {
      final client = Supa.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final jwt = _getValidJWT();
      if (jwt == null) return null; // Already redirected to login

      final response = await http.post(
        Uri.parse(_svSummarizeRunUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'run_id': runId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            'Summarize run failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error calling summarize run: $e');
      return null;
    }
  }

  /// Call summarize-transcript edge function as fallback
  Future<Map<String, dynamic>?> callSummarizeTranscript(
      String transcriptText) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock summarize transcript');
      return {
        'summary':
            'Preview mode: This would be an AI-generated summary of the provided transcript text.',
        'success': true
      };
    }

    try {
      final client = Supa.client;

      final jwt = _getValidJWT();
      if (jwt == null) return null; // Already redirected to login

      final response = await http.post(
        Uri.parse(_summarizeTranscriptUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'transcript_text': transcriptText}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            'Summarize transcript failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error calling summarize transcript: $e');
      return null;
    }
  }

  /// Get signed download URL for audio
  Future<String?> getSignedAudioDownloadUrl(String storagePath) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock signed audio download URL');
      return 'https://preview-mock.supabase.co/storage/v1/object/sign/recordings/preview-audio.webm?token=preview-token';
    }

    try {
      final client = Supa.client;

      final jwt = _getValidJWT();
      if (jwt == null) return null; // Already redirected to login

      final response = await http.post(
        Uri.parse(_svSignAudioDownloadUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'storage_path': storagePath}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['signedUrl'] as String?;
      } else {
        debugPrint(
            'Sign audio download failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting signed audio download URL: $e');
      return null;
    }
  }

  /// Determine current processing state based on note run and events
  String determineState(
      Map<String, dynamic>? noteRun, List<Map<String, dynamic>> events) {
    if (noteRun == null) return 'error';

    final status = noteRun['status'] as String?;
    final hasTranscript = noteRun['transcript_text'] != null &&
        (noteRun['transcript_text'] as String).trim().isNotEmpty;
    final hasSummary = noteRun['summary_v1'] != null;
    final hasError = noteRun['error_msg'] != null;

    if (hasError) return 'error';
    if (hasSummary) return 'ready';
    if (hasTranscript) return 'summarizing';

    // Check events for more specific state
    final latestEvent = events.isNotEmpty ? events.last : null;
    if (latestEvent != null) {
      final eventType = latestEvent['event'] as String?;
      switch (eventType) {
        case 'transcription_started':
        case 'asr_job_started':
          return 'transcribing';
        case 'transcription_completed':
          return 'summarizing';
        case 'summary_completed':
          return 'ready';
        case 'error':
          return 'error';
      }
    }

    // Fallback based on status
    switch (status) {
      case 'uploaded':
      case 'transcribing':
        return 'transcribing';
      case 'transcribed':
        return 'summarizing';
      case 'summarized':
        return 'ready';
      case 'error':
        return 'error';
      default:
        return 'loading';
    }
  }

  /// Create transcript entry in transcripts table if needed
  Future<String?> createTranscriptEntry({
    required String audioUrl,
    required String transcriptText,
    String? summary,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock create transcript entry');
      return 'preview-transcript-${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final client = Supa.client;
      final userId = await AuthX.requireUserId();

      if (audioUrl.isEmpty || transcriptText.isEmpty) {
        throw Exception('audioUrl and transcriptText cannot be empty');
      }

      final response = await client
          .from('transcripts')
          .insert({
            'user_id': userId,
            'audio_url': audioUrl,
            'transcript': {'text': transcriptText},
            'summary': summary,
            'status': 'completed',
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating transcript entry: $e');
      return null;
    }
  }
}
