import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../bootstrap_supabase.dart';

class UploadResult {
  final String runId;
  final String storagePath;
  UploadResult({required this.runId, required this.storagePath});
}

class SupaUpload {
  static final _uuid = const Uuid();

  static Future<String> _requireUserId() async {
    final user = Supa.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.id;
  }

  /// Upload a recording to Storage and insert a DB row.
  /// Includes soft quotas and file size guardrails.
  static Future<UploadResult> uploadRecording({
    required File file,
    required Duration duration,
    required String mime, // 'audio/wav' on Windows; 'audio/m4a' elsewhere
  }) async {
    final userId = await _requireUserId();
    final runId = _uuid.v4();
    final ext = mime.contains('wav') ? 'wav' : 'm4a';
    final fileName = '$runId.$ext';
    final storagePath = 'user/$userId/$fileName';
    final storage = Supa.client.storage.from('audio');

    // ----- Guardrails -----
    // File size cap (client-side). Tweak as needed.
    const maxBytes = 50 * 1024 * 1024; // 50 MB
    final size = await file.length();
    if (size > maxBytes) {
      throw Exception('File too large (${(size / (1024 * 1024)).toStringAsFixed(1)} MB). '
          'Limit is ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)} MB.');
    }

    // Soft quota: max N recordings per user (client-side).
    // NOTE: This is advisory; RLS still protects ownership. For hard limits,
    // add a DB trigger or enforce via an Edge Function that issues signed URLs.
    const maxRecordingsPerUser = 500;
    final countResp = await Supa.client
        .from('recordings')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId);
    final currentCount = countResp.count ?? 0;
    if (currentCount >= maxRecordingsPerUser) {
      throw Exception('Quota exceeded: max $maxRecordingsPerUser recordings per user.');
    }
    // ----------------------

    // 1) Upload to Storage
    await storage.upload(
      storagePath,
      file,
      fileOptions: FileOptions(contentType: mime, upsert: false),
    );

    try {
      // 2) Insert DB row (throws PostgrestException on failure)
      await Supa.client.from('recordings').insert({
        'user_id': userId,
        'run_id': runId,
        'storage_path': storagePath,
        'duration_ms': duration.inMilliseconds,
        'status': 'uploaded',
      });
    } catch (e) {
      // Roll back storage if DB insert fails
      try { await storage.remove([storagePath]); } catch (_) {}
      rethrow;
    }

    return UploadResult(runId: runId, storagePath: storagePath);
  }

  /// Delete the file from Storage and its DB row (by runId), scoped to current user.
  static Future<void> deleteRecording({
    required String runId,
    required String storagePath,
  }) async {
    final userId = await _requireUserId();

    // Delete DB row first so UI lists don’t show ghosts.
    await Supa.client
        .from('recordings')
        .delete()
        .match({'user_id': userId, 'run_id': runId});

    // Then delete object from Storage.
    final storage = Supa.client.storage.from('audio');
    await storage.remove([storagePath]);
  }

  /// Fetch recent recordings for the current user (RLS enforces isolation).
  static Future<List<Map<String, dynamic>>> listMyRecordings({int limit = 20}) async {
    await _requireUserId(); // ensures logged in
    final rows = await Supa.client
        .from('recordings')
        .select('run_id, storage_path, duration_ms, status, created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    // Supabase Dart returns dynamic; coerce to List<Map<String, dynamic>>
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
