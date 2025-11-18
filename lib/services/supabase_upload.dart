// lib/services/supabase_upload.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';
import './auth.dart';
import './recording_backend_service.dart';

class UploadResult {
  final String runId;
  final String storagePath;
  UploadResult({required this.runId, required this.storagePath});
}

class SupaUpload {
  static final _uuid = const Uuid();

  static Future<String> _requireUserId() async {
    return await AuthX.requireUserId();
  }

  /// Upload a recording to Storage and insert a DB row.
  /// NOTE: This is legacy/utility code. Your main flow uses `Pipeline`.
  static Future<UploadResult> uploadRecording({
    required File file,
    required Duration duration,
    required String mime, // e.g. 'audio/wav' or 'audio/m4a'
  }) async {
    final userId = await _requireUserId();
    final runId = _uuid.v4();
    final ext = mime.contains('wav') ? 'wav' : 'm4a';
    final fileName = '$runId.$ext';
    final storagePath = 'user/$userId/$fileName';

    // Bucket name kept as in your original file. Change to 'recordings' if needed.
    final storage = Supa.client.storage.from('audio');

    // ----- Guardrails -----
    const maxBytes = 50 * 1024 * 1024; // 50 MB
    final size = await file.length();
    if (size > maxBytes) {
      throw Exception(
        'File too large (${(size / (1024 * 1024)).toStringAsFixed(1)} MB). '
        'Limit is ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
      );
    }

    // Soft quota (client-side): count by fetching ids and taking length.
    // This avoids the old FetchOptions API entirely.
    const maxRecordingsPerUser = 500;
    final rows =
        await Supa.client.from('recordings').select('id').eq('user_id', userId);
    final currentCount = (rows as List).length;
    if (currentCount >= maxRecordingsPerUser) {
      throw Exception(
          'Quota exceeded: max $maxRecordingsPerUser recordings per user.');
    }
    // ----------------------

    // 1) Upload to Storage
    await storage.upload(
      storagePath,
      file,
      fileOptions: FileOptions(contentType: mime, upsert: false),
    );

    try {
      // 2) Insert DB row using safe insert helper
      // Note: Status starts as 'uploading' - edge function will transition to 'transcribing' when pipeline starts
      final payload = <String, dynamic>{
        'user_id': userId,
        'storage_path': storagePath,
        'trace_id': runId,
        'status': 'uploading',
        'original_filename': fileName,
        'mime_type': mime,
        'duration_sec': (duration.inMilliseconds / 1000).round(),
      };
      
      await RecordingBackendService.instance.safeInsertRecording(
        supabase: Supa.client,
        payload: payload,
        traceId: runId,
      );
    } catch (e) {
      // Roll back storage if DB insert fails
      try {
        await storage.remove([storagePath]);
      } catch (_) {}
      rethrow;
    }

    return UploadResult(runId: runId, storagePath: storagePath);
  }

  /// Delete file+row scoped to current user.
  static Future<void> deleteRecording({
    required String runId,
    required String storagePath,
  }) async {
    final userId = await _requireUserId();

    await Supa.client
        .from('recordings')
        .delete()
        .match({'user_id': userId, 'run_id': runId});

    final storage = Supa.client.storage.from('audio');
    await storage.remove([storagePath]);
  }

  /// Fetch recent recordings for current user.
  static Future<List<Map<String, dynamic>>> listMyRecordings(
      {int limit = 20}) async {
    final userId = await _requireUserId();
    final rows = await Supa.client
        .from('recordings')
        .select('run_id, storage_path, duration_ms, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows as List);
  }
}
