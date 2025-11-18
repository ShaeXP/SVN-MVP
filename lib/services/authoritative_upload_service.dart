import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, VoidCallback, kDebugMode;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/auth_guard.dart';
import 'pipeline_tracker.dart';
import 'logger.dart';
import '../debug/metrics_tracker.dart';
import 'pipeline_trigger_service.dart';

/// Authoritative upload service that follows the exact flow specified:
/// 1. Generate identifiers and safe names
/// 2. Pre-create DB row (so Library shows immediately)
/// 3. Upload to Supabase Storage
/// 4. Trigger edge function
/// 5. Show appropriate toasts
///
/// PIPELINE FLOW:
/// - UI entrypoints: Upload Audio File, Record Live
/// - Storage path: recordings/<userId>/YYYY/MM/DD/timestamp-traceId-filename.ext
/// - Edge function: sv_run_pipeline (Deepgram -> OpenAI -> Resend email)
/// - Status progression: uploading -> transcribing -> summarizing -> ready
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
    String? summaryStyleOverride,
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

    logx('[PIPELINE][$traceId] Generated object name: $objectName', tag: 'PIPE');
    debugPrint('[PIPELINE][$traceId] Generated object name: $objectName');

    // Pre-create DB row (so Library has something to show immediately)
    // Note: 'title' is not included in insertData as it may not exist in schema
    final insertData = <String, dynamic>{
      'user_id': user.id,
      'status': 'uploading',
      'storage_path': objectName,
      if (durationMs != null) 'duration_sec': (durationMs / 1000).round(),
      // Note: 'trace_id' is not included as it may not exist in schema
    };

    logx('[PIPELINE][$traceId] Pre-inserting DB row...', tag: 'PIPE');
    debugPrint('[PIPELINE][$traceId] Pre-inserting DB row...');
    final insertResult = await _supabase
        .from('recordings')
        .insert(insertData)
        .select('id,created_at,storage_path')
        .maybeSingle();

    if (insertResult == null) {
      logx('[PIPELINE][$traceId] Failed to create recording row - check RLS permissions', tag: 'PIPE', error: 'DBInsertFailed');
      throw Exception('Failed to create recording row - check RLS permissions');
    }

    final recordingId = insertResult['id'] as String;
    logx('[PIPELINE][$traceId] DB row created: recordingId=$recordingId', tag: 'PIPE');
    debugPrint('[PIPELINE][$traceId] pre-insert ok → $recordingId');

    try {
      // Upload to Supabase Storage (block until success) - direct Flutter → Supabase Storage
      final contentType = _getContentType(originalFilename);
      final fileSize = fileBytes.lengthInBytes;
      
      final uploadStartedAt = DateTime.now();
      logx('[PIPELINE][$traceId] Uploading to storage: filename=$originalFilename, extension=${_getFileExtension(originalFilename)}, contentType=$contentType, size=${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(1)}KB), objectName=$objectName${durationMs != null ? ', duration=${(durationMs / 1000).round()}s' : ''}', tag: 'PIPE');
      debugPrint('[UPLOAD] starting upload for recording $recordingId, '
          'size=${fileSize}B (${(fileSize / 1024).toStringAsFixed(1)}KB), '
          'path=$objectName${durationMs != null ? ', duration=${(durationMs / 1000).round()}s' : ''}');
      debugPrint('[UPLOAD] signer ct=$contentType method=PUT host=storage.supabase.co bucket=recordings');
      
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

      final uploadFinishedAt = DateTime.now();
      final elapsedMs = uploadFinishedAt.difference(uploadStartedAt).inMilliseconds;
      logx('[PIPELINE][$traceId] Storage upload completed: $objectName in ${elapsedMs}ms', tag: 'PIPE');
      debugPrint('[UPLOAD] finished upload for $recordingId in ${elapsedMs}ms '
          '(size=${fileSize}B, path=$objectName)');

      // Track upload metrics (debug only)
      if (kDebugMode) {
        MetricsTracker.I.trackUpload(
          recordingId: recordingId,
          sizeBytes: fileSize,
          elapsedMs: elapsedMs,
          startedAt: uploadStartedAt,
        );
      }

      // Update status to confirm upload success
      await _supabase
          .from('recordings')
          .update({'status': 'uploading'})
          .eq('id', recordingId);

      // Start pipeline tracking (this sets PipelineTracker.recordingId.value)
      PipelineTracker.I.start(recordingId, openHud: false);

      // Use the unified pipeline trigger service
      onFunctionInvoke?.call(); // Notify that function invoke started
      
      logx('[PIPELINE][$traceId] Invoking sv_run_pipeline edge function via unified service...', tag: 'PIPE');
      debugPrint('[PIPELINE][$traceId] Triggering edge function via unified service...');
      
      // Get storage path from objectName (remove bucket prefix if present)
      final storagePath = objectName.startsWith('recordings/') 
          ? objectName 
          : 'recordings/$objectName';
      
      // Use unified pipeline trigger service
      await PipelineTriggerService.instance.runPipelineForRecording(
        recordingId: recordingId,
        storagePath: storagePath,
        summaryStyleKeyOverride: summaryStyleOverride,
      );
      
      logx('[PIPELINE][$traceId] Pipeline triggered successfully', tag: 'PIPE');
      debugPrint('[PIPELINE][$traceId] Pipeline triggered successfully');

      // Success - show toast only after DB insert + storage upload success
      logx('[PIPELINE][$traceId] Pipeline started successfully: recordingId=$recordingId', tag: 'PIPE');
      return {
        'success': true,
        'message': 'Upload queued • You\'ll see it in Library shortly',
        'recording_id': recordingId,
        'trace_id': traceId,
      };

    } catch (e, stackTrace) {
      // Upload or function failed - update DB status
      logx('[PIPELINE][$traceId] Upload or pipeline failed: $e', tag: 'PIPE', error: e, stack: stackTrace);
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
  /// Note: Supabase storage requires 'audio/m4a' for .m4a files, not 'audio/mp4'
  String _getContentType(String filename) {
    final ext = _getFileExtension(filename);
    logx('[PIPELINE] Determining contentType for file: $filename (extension: $ext)', tag: 'PIPE');
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/m4a'; // Supabase requires 'audio/m4a', not 'audio/mp4'
      case 'mp4':
        // For actual MP4 video files, use video/mp4, but we typically don't upload video
        // If this is audio in MP4 container, consider using 'audio/m4a' instead
        return 'audio/m4a'; // Use audio/m4a for compatibility with Supabase storage
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

  /// Shared helper to start pipeline from a local file path.
  /// Used by both Upload Audio File and Record Live flows.
  /// 
  /// Steps:
  /// 1. Read file bytes from local path
  /// 2. Generate storage path and identifiers
  /// 3. Create recordings DB row
  /// 4. Upload to Supabase Storage
  /// 5. Invoke sv_run_pipeline edge function
  /// 
  /// Returns map with success status, recording_id, trace_id, and message.
  Future<Map<String, dynamic>> startPipelineFromLocalFile({
    required String localFilePath,
    required String sourceType, // 'upload' or 'record'
    String? userTitle,
    int? durationMs,
  }) async {
    final traceId = _uuid.v4().substring(0, 8);
    logx('[PIPELINE] startPipelineFromLocalFile called: sourceType=$sourceType, path=$localFilePath, trace=$traceId', tag: 'PIPE');

    try {
      // Step 1: Read file bytes
      logx('[PIPELINE][$traceId] Reading file bytes...', tag: 'PIPE');
      final file = File(localFilePath);
      if (!await file.exists()) {
        logx('[PIPELINE][$traceId] File does not exist: $localFilePath', tag: 'PIPE', error: 'FileNotFound');
        return {
          'success': false,
          'error': 'File not found',
          'message': 'Recorded file not found at path',
          'trace_id': traceId,
        };
      }

      final fileBytes = await file.readAsBytes();
      final originalFilename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'recording.m4a';

      logx('[PIPELINE][$traceId] File read: ${fileBytes.length} bytes, filename=$originalFilename, extension=${originalFilename.split('.').last}', tag: 'PIPE');

      // Step 2-5: Use existing upload flow
      final result = await uploadWithAuthoritativeFlow(
        fileBytes: fileBytes,
        originalFilename: originalFilename,
        userTitle: userTitle,
        durationMs: durationMs,
      );

      logx('[PIPELINE][$traceId] Pipeline started: success=${result['success']}, recording_id=${result['recording_id']}', tag: 'PIPE');
      return result;
    } catch (e, stackTrace) {
      logx('[PIPELINE][$traceId] startPipelineFromLocalFile failed: $e', tag: 'PIPE', error: e, stack: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to start pipeline: ${e.toString()}',
        'trace_id': traceId,
      };
    }
  }
}
