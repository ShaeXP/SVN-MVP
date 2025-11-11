import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, VoidCallback;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../utils/auth_guard.dart';
import 'pipeline_tracker.dart';

/// Authoritative upload service that follows the exact flow specified:
/// 1. Generate identifiers and safe names
/// 2. Pre-create DB row (so Library shows immediately)
/// 3. Upload to Supabase Storage
/// 4. Trigger edge function
/// 5. Show appropriate toasts
class AuthoritativeUploadService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Pick and upload audio file with the authoritative flow
  Future<Map<String, dynamic>> pickAndUploadAudioFile() async {
    try {
      debugPrint('[PIPELINE] Starting file picker for audio upload...');

      // Step 1: Pick audio file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'webm', 'ogg'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return {
          'success': false,
          'error': 'No file selected',
          'message': 'File selection was cancelled'
        };
      }

      final PlatformFile file = result.files.first;
      debugPrint('[UPLOAD] picked name=${file.name} size=${file.size}');

      // Get file bytes
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        if (file.path != null) {
          final ioFile = File(file.path!);
          fileBytes = await ioFile.readAsBytes();
        }
      }

      if (fileBytes == null) {
        return {
          'success': false,
          'error': 'Could not read file',
          'message': 'Failed to read the selected file'
        };
      }

      // Upload with authoritative flow
      final uploadResult = await uploadWithAuthoritativeFlow(
        fileBytes: fileBytes,
        originalFilename: file.name,
      );

      return uploadResult;
    } catch (e) {
      debugPrint('[PIPELINE] Upload error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'File upload failed due to an unexpected error'
      };
    }
  }

  /// Upload bytes with the authoritative flow
  Future<Map<String, dynamic>> uploadWithAuthoritativeFlow({
    required Uint8List fileBytes,
    required String originalFilename,
    String? userTitle,
    int? durationMs,
    VoidCallback? onFunctionInvoke,
  }) async {
    final session = AuthGuard.requireSession();
    final user = session.user;

    // Generate identifiers
    final traceId = _uuid.v4().substring(0, 8);
    final now = DateTime.now();

    // Build safe names with proper extension
    final ts = DateFormat('yyyyMMdd_HHmmss').format(now);
    final y = DateFormat('yyyy').format(now);
    final m = DateFormat('MM').format(now);
    final d = DateFormat('dd').format(now);
    final safeBase = (originalFilename.split('.').first).toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '-');
    final extension = _getFileExtension(originalFilename);
    final objectName = 'recordings/${user.id}/$y/$m/$d/$ts-$traceId-$safeBase.$extension';

    debugPrint('[PIPELINE][$traceId] Generated object name: $objectName');

    // Pre-create DB row (so Library has something to show immediately)
    final title = userTitle ?? 'Voice note ${DateFormat('h:mm a').format(now)}';
    final insertData = {
      'user_id': user.id,
      'title': title,
      'status': 'uploading',
      'storage_path': objectName,
      'trace_id': traceId,
      if (durationMs != null) 'duration_sec': (durationMs / 1000).round(),
    };
    insertData.removeWhere((k, v) => v == null);
    insertData.remove('title');
    insertData.remove('trace_id'); // optional key; schema may not have it

    debugPrint('[PIPELINE][$traceId] Pre-inserting DB row...');
    final insertResult = await _supabase
        .from('recordings')
        .insert(insertData)
        .select('id,created_at,storage_path')
        .maybeSingle();

    if (insertResult == null) {
      throw Exception('Failed to create recording row - check RLS permissions');
    }

    final recordingId = insertResult['id'] as String;
    debugPrint('[PIPELINE][$traceId] pre-insert ok → $recordingId');

    // Start pipeline tracking for real-time progress updates
    PipelineTracker.I.start(recordingId, openHud: false);

    try {
      // Upload to Supabase Storage (block until success)
      final contentType = _getContentType(originalFilename);
      debugPrint('[UPLOAD] signer ct=$contentType method=PUT host=storage.supabase.co bucket=recordings');
      debugPrint('[PIPELINE][$traceId] Uploading to storage with contentType=$contentType...');
      await _supabase.storage
          .from('recordings')
          .uploadBinary(
            objectName.replaceFirst('recordings/', ''), // Remove bucket prefix for storage API
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      debugPrint('[PIPELINE][$traceId] storage ok → $objectName');

      // Update status to confirm upload success
      await _supabase
          .from('recordings')
          .update({'status': 'uploading'})
          .eq('id', recordingId);

      // Trigger edge function
      debugPrint('[PIPELINE][$traceId] Triggering edge function...');
      onFunctionInvoke?.call(); // Notify that function invoke started
      final resp = await _supabase.functions.invoke(
        'sv_run_pipeline',
        body: {
          'recordingId': recordingId,
          'traceId': traceId,
        },
      );

      debugPrint('[PIPELINE][$traceId] function resp → ${resp.status}');

      if (resp.status >= 300) {
        // Update status to error
        await _supabase
            .from('recordings')
            .update({
              'status': 'error',
              'last_error': 'function ${resp.status}',
            })
            .eq('id', recordingId);

        return {
          'success': false,
          'error': 'Pipeline function failed',
          'message': 'Upload completed but processing failed. Tap for details.',
          'recording_id': recordingId,
          'trace_id': traceId,
        };
      }

      // Success - show toast only after DB insert + storage upload success
      return {
        'success': true,
        'message': 'Upload queued • You\'ll see it in Library shortly',
        'recording_id': recordingId,
        'trace_id': traceId,
      };

    } catch (e) {
      // Upload or function failed - update DB status
      await _supabase
          .from('recordings')
          .update({
            'status': 'error',
            'last_error': e.toString(),
          })
          .eq('id', recordingId);

      debugPrint('[PIPELINE][$traceId] Upload failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Upload failed: ${e.toString()}',
        'recording_id': recordingId,
        'trace_id': traceId,
      };
    }
  }

  /// Get file extension from filename
  String _getFileExtension(String filename) {
    final parts = filename.toLowerCase().split('.');
    if (parts.length < 2) return 'm4a';
    final ext = parts.last;
    // Support MP3, WAV, and existing types
    if (['mp3', 'wav', 'm4a', 'aac', 'webm', 'ogg'].contains(ext)) {
      return ext;
    }
    return 'm4a'; // fallback
  }

  /// Get MIME type from filename
  String _getContentType(String filename) {
    final ext = _getFileExtension(filename);
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
      case 'mp4':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'webm':
        return 'audio/webm';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/m4a'; // fallback
    }
  }
}
