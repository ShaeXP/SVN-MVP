import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'logger.dart';
import 'db_schema_probe.dart';

class RecordingBackendService {
  RecordingBackendService._();
  static final instance = RecordingBackendService._();

  final _sb = Supabase.instance.client;
  final _uuid = const Uuid();
  final _schemaProbe = DbSchemaProbe(Supabase.instance.client);

  // ---- SAFE INSERT HELPER ----
  Future<Map<String, dynamic>> safeInsertRecording({
    required SupabaseClient supabase,
    required Map<String, dynamic> payload,
    required String traceId,
  }) async {
    // Remove nulls and known-problematic optional keys up-front
    payload.removeWhere((k, v) => v == null);
    if (payload.containsKey('title')) {
      payload.remove('title');
      debugPrint("[UPLOAD][$traceId] removed 'title' pre-insert");
    }

    // Try up to 5 times; strip any unknown columns reported by PostgREST.
    const maxTries = 5;
    var tries = 0;
    while (true) {
      tries++;
      try {
        debugPrint("[UPLOAD][$traceId] payload keys=${payload.keys.toList()}");
        // Minimal, schema-safe projection (avoid selecting optional columns)
        return await supabase
            .from('recordings')
            .insert(payload)
            .select('id,created_at,storage_path') // ← only guaranteed columns
            .single();
      } on PostgrestException catch (e) {
        final msg = e.message ?? e.toString();
        final m = RegExp(r"Could not find the '([A-Za-z0-9_]+)' column").firstMatch(msg);
        if (m != null && tries < maxTries) {
          final bad = m.group(1)!;
          // Never strip required keys
          if (bad == 'user_id' || bad == 'storage_path') rethrow;
          if (payload.remove(bad) != null) {
            debugPrint("[UPLOAD][$traceId] dropping '$bad' then retry ($tries/$maxTries)");
            continue;
          }
        }
        // Baseline scrub (one-time) if we hit an unknown column in SELECT or elsewhere
        if (tries == 1) {
          final safe = {'user_id','storage_path'}; // keep it ultra-minimal
          payload.removeWhere((k, _) => !safe.contains(k));
          debugPrint("[UPLOAD][$traceId] scrubbed to baseline keys=${payload.keys.toList()} and retrying");
          continue;
        }
        rethrow;
      }
    }
  }

  // ---- MIME MAP ----
  static String _contentTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'm4a':
      case 'mp4': // audio in mp4 container -> use audio/mp4
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'caf':
        return 'audio/x-caf';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      default:
        // Block unknowns instead of uploading as octet-stream (bucket rejects it anyway)
        throw UnsupportedError('Unsupported file type: .$ext');
    }
  }

  static String _sanitizeName(String name) {
    // basic cleanup to avoid weird chars in object path
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }

  /// Upload local audio file to bucket 'recordings'.
  /// Returns storage_path like: recordings/<userId>/<uuid>-<filename.ext>
  Future<String> uploadLocalAudio({
    required String userId,
    required File file,
  }) async {
    final baseName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'audio.m4a';
    final safeName = _sanitizeName(baseName);
    // object path should NOT include the bucket name
    final objectPath = '$userId/${_uuid.v4()}-$safeName';

    final contentType = _contentTypeFor(safeName);

    final bytes = await file.readAsBytes();
    final res = await _sb.storage
        .from('recordings')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );

    if (res == null || res.isEmpty) {
      throw Exception('Upload failed: empty response from storage');
    }

    logx('[UPLOAD] storage ok "$objectPath" ($contentType)', tag: 'UPLOAD');
    // Return path INCLUDING bucket for your DB (bucket + object)
    return 'recordings/$objectPath';
  }

  Future<String> upsertRecordingRow({
    required String userId,
    required String storagePath,
    required String traceId,
    String status = 'uploading',
    int? durationSec,
    String? uiTitle,
    String? originalFilename,
  }) async {
    // Build minimal, schema-tolerant payload
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'storage_path': storagePath,
      'trace_id': traceId,
      'status': status,
      if (originalFilename != null) 'original_filename': originalFilename,
      'mime_type': 'audio/m4a',
      if (durationSec != null) 'duration_sec': durationSec,
      if (uiTitle != null) 'title': uiTitle,
    };

    debugPrint("[UPLOAD][$traceId] payload keys=${payload.keys.toList()}");
    
    final rec = await safeInsertRecording(
      supabase: _sb,
      payload: payload,
      traceId: traceId,
    );
    
    final id = rec['id'] as String;
    debugPrint("[UPLOAD][$traceId] insert ok id=$id");
    return id;
  }

  Future<void> setRecordingStatus({
    required String recordingId,
    required String userId,
    required String status,
    String? errorMsg,
  }) async {
    final upd = <String, dynamic>{
      'status': status,
      if (errorMsg != null) 'last_error': errorMsg,
    };
    // Remove nulls before update
    upd.removeWhere((k, v) => v == null);
    
    try {
      await _sb.from('recordings').update(upd).eq('id', recordingId).eq('user_id', userId);
      logx('[DB] recording $recordingId status -> $status', tag: 'PIPE');
    } catch (e) {
      // If update fails due to missing columns, try with just the status
      if (upd.containsKey('last_error')) {
        try {
          await _sb.from('recordings').update({'status': status}).eq('id', recordingId).eq('user_id', userId);
          logx('[DB] recording $recordingId status -> $status (last_error column missing)', tag: 'PIPE');
        } catch (_) {
          logx('[DB] recording $recordingId status update failed', tag: 'PIPE');
        }
      }
    }
  }

  Future<void> runSvPipeline({
    required String recordingId,
    required String storagePath,
    String? runId,
  }) async {
    final trace = runId ?? '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_uuid.v1().substring(0, 6)}';
    logx('[PIPELINE] Invoking sv_run_pipeline: rid=$recordingId, path=$storagePath, trace=$trace', tag: 'PIPE');

    try {
      final resp = await _sb.functions.invoke(
        'sv_run_pipeline',
        headers: {'x-trace-id': trace},
        body: {
          'recording_id': recordingId,
          'storage_path': storagePath,
          'run_id': trace,
        },
      );

      debugPrint('[UPLOAD][$trace] fn status=${resp.status}');
      
      if (resp.status >= 300) {
        final err = resp.data is Map ? (resp.data['message']?.toString() ?? '') : resp.data?.toString() ?? '';
        logx('[PIPELINE] sv_run_pipeline failed (${resp.status}): $err', tag: 'PIPE', error: err.isEmpty ? 'unknown' : err);
        throw Exception('sv_run_pipeline failed (${resp.status}): ${err.isEmpty ? "No error message" : err}');
      }
      logx('[PIPELINE] sv_run_pipeline completed successfully', tag: 'PIPE');
    } catch (e, stackTrace) {
      logx('[PIPELINE] Exception during invoke: $e', tag: 'PIPE', error: e, stack: stackTrace);
      rethrow;
    }
  }

  /// Insert-then-upload sequence with proper error handling
  Future<Map<String, dynamic>> insertThenUpload({
    required File file,
    required String userId,
    int? durationSec,
    String? uiTitle,
  }) async {
    final traceId = _uuid.v4().substring(0, 8);
    
    // Generate storage path and object name
    final baseName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'audio.m4a';
    final safeName = _sanitizeName(baseName);
    final objectName = '$userId/${_uuid.v4()}-$safeName';
    final storagePath = 'recordings/$objectName';
    
    try {
      // Build minimal, schema-tolerant payload (only safe keys; nothing schema-changing)
      final Map<String, dynamic> payload = {
        'user_id': userId,                 // keep: RLS
        'storage_path': objectName,        // keep: required for pipeline
        'trace_id': traceId,               // optional; will be dropped if table lacks it
        // Optional keys (will be auto-dropped if table doesn't have them):
        'status': 'uploading',
        'original_filename': baseName,
        'mime_type': 'audio/m4a',
        if (durationSec != null) 'duration_sec': durationSec,
        if (uiTitle != null) 'title': uiTitle,  // <-- will be removed if schema lacks 'title'
      };

      debugPrint("[UPLOAD][$traceId] payload keys=${payload.keys.toList()}");
      
      // Step 1: Insert DB row first using safe insert helper
      final rec = await safeInsertRecording(
        supabase: _sb,
        payload: payload,
        traceId: traceId,
      );

      final recId = rec['id'] as String;
      debugPrint("[UPLOAD][$traceId] insert ok id=$recId");
      
      // Step 2: Upload to storage
      final bytes = await file.readAsBytes();
      final uploadRes = await _sb.storage
          .from('recordings')
          .uploadBinary(objectName, bytes,
            fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: false));

      if (uploadRes == null || uploadRes.isEmpty) {
        // Update row to status='error' if that column exists
        try {
          await _sb.from('recordings').update({'status': 'error'}).eq('id', recId);
        } catch (_) {
          // Ignore if status column doesn't exist
        }
        return {
          'success': false,
          'error': 'Storage upload failed',
          'message': 'Upload failed: storage upload failed',
          'trace_id': traceId,
        };
      }
      
      debugPrint('[UPLOAD][$traceId] storage ok $objectName');
      
      // Step 3: Only after insert and storage upload succeed → show success and invoke pipeline
      if (recId.isEmpty || storagePath.isEmpty) {
        debugPrint('[UPLOAD][$traceId] missing required params: recId=$recId, storagePath=$storagePath');
        return {
          'success': false,
          'error': 'Missing required parameters',
          'message': 'Upload failed: missing recording ID or storage path',
          'trace_id': traceId,
        };
      }
      
      final functionBody = {
        'recording_id': recId,
        'recordingId': recId, // fallback for camelCase
        'storage_path': storagePath,
        'storagePath': storagePath, // fallback for camelCase
        'trace_id': traceId,
        'traceId': traceId, // fallback for camelCase
      };
      debugPrint('[UPLOAD][$traceId] invoking pipeline with keys=${functionBody.keys.toList()}');
      debugPrint('[UPLOAD][$traceId] function body values: recording_id=$recId, storage_path=$storagePath, trace_id=$traceId');
      
      final fn = await _sb.functions.invoke(
        'sv_run_pipeline', 
        body: functionBody,
        headers: {
          'Content-Type': 'application/json',
          'x-trace-id': traceId,
        },
      );

      debugPrint('[UPLOAD][$traceId] fn status=${fn.status}');
      debugPrint('[UPLOAD][$traceId] fn data=${fn.data}');

      if ((fn.status ?? 500) >= 300) {
        // Mark error if schema supports it
        try {
          await _sb.from('recordings').update({
            'status': 'error',
            'last_error': 'sv_run_pipeline ${fn.status}'
          }).eq('id', recId);
        } catch (_) {
          // Ignore if status/last_error columns don't exist
        }
        return {
          'success': false,
          'error': 'Pipeline function failed',
          'message': 'Upload completed but processing failed. Tap for details.',
          'recording_id': recId,
          'trace_id': traceId,
        };
      }
      
      // Success toast here (and ONLY here)
      return {
        'success': true,
        'recording_id': recId,
        'trace_id': traceId,
        'message': 'Upload queued',
      };
      
    } on PostgrestException catch (e) {
      // On insert error (after retry): toast Upload failed (DB insert) and STOP
      return {
        'success': false,
        'error': e.message,
        'message': 'Upload failed (DB insert): ${e.message}',
        'trace_id': traceId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Upload failed: ${e.toString()}',
        'trace_id': traceId,
      };
    }
  }

  Future<String> uploadAndRun({
    required File file,
    required String userId,
  }) async {
    final result = await insertThenUpload(
      file: file,
      userId: userId,
      uiTitle: 'Voice note ${DateTime.now().toIso8601String()}',
    );
    
    if (result['success'] == true) {
      return result['recording_id'] as String;
    } else {
      throw Exception(result['error'] ?? 'Upload failed');
    }
  }

  /// Legacy method for backward compatibility with file_upload_service
  /// Processes a recording blob by creating temp file
  Future<Map<String, dynamic>> processStopRecording({
    required List<int> recordingBlob,
    required int durationMs,
    String fileName = 'recording.m4a',
  }) async {
    try {
      logx('[PROCESS] Starting processStopRecording: ${recordingBlob.length} bytes, fileName=$fileName', tag: 'UPLOAD');
      
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) {
        logx('[PROCESS] Auth check failed - no user', tag: 'UPLOAD');
        return {
          'success': false,
          'error': 'Not authenticated',
          'message': 'User must be signed in to upload recordings'
        };
      }
      logx('[PROCESS] User authenticated: $userId', tag: 'UPLOAD');

      // Create temporary file from blob
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}_$fileName');
      await tempFile.writeAsBytes(recordingBlob);

      try {
        // Use insert-then-upload sequence
        logx('[PROCESS] Using insert-then-upload sequence...', tag: 'UPLOAD');
        final result = await insertThenUpload(
          file: tempFile,
          userId: userId,
          durationSec: (durationMs / 1000).round(),
          uiTitle: 'Voice note ${DateTime.now().toIso8601String()}',
        );

        return result;
      } finally {
        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e, stackTrace) {
      logx('[PROCESS] processStopRecording error: $e', tag: 'UPLOAD', error: e, stack: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to process recording: ${e.toString()}'
      };
    }
  }
}
