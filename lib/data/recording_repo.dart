import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth.dart';

class RecordingRepo {
  final supa = Supabase.instance.client;

  /// Fetch recordings from the canonical 'recordings' bucket only.
  /// Filters out legacy recordings from 'audio' and 'recording' buckets.
  Future<List<Map<String, dynamic>>> fetchRecordings() async {
    final userId = await AuthX.requireUserId();
    final table = supa.from('recordings');
    final rows = await table
        .select('id, user_id, storage_path, status, created_at, run_id')
        .eq('user_id', userId)
        .like('storage_path', 'recordings/%')  // Only show canonical bucket
        .order('created_at', ascending: false);
    
    // Debug: log the status values being returned
    for (final row in rows) {
      print('[RecordingRepo] Fetched recording: id=${row['id']}, status=${row['status']}');
    }
    
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Stream recordings with real-time updates from the canonical 'recordings' bucket only.
  /// Uses polling for compatibility with current Supabase version.
  Stream<List<Map<String, dynamic>>> streamMyRecordings() async* {
    // Emit initial data immediately
    yield await fetchRecordings();
    
    // Then emit updates every 2 seconds (faster for testing)
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      yield await fetchRecordings();
    }
  }

  /// Insert a shadow row so Library updates instantly after upload.
  /// IMPORTANT: do NOT set `status` explicitly (DB enum default will populate it).
  Future<({String recordingId, String runId})> createRecordingRow({
    required String storagePath,
  }) async {
    final userId = await AuthX.requireUserId();
    final data = {'user_id': userId, 'storage_path': storagePath};
    final res = await Supabase.instance.client
        .from('recordings')
        .insert(data)
        .select('id, run_id')
        .single();
    return (recordingId: res['id'] as String, runId: res['run_id'] as String);
  }

  // Stream ONE recording row (by id) — live status + fields
  Stream<Map<String, dynamic>?> streamRecording(String recordingId) {
    if (recordingId.isEmpty) {
      // ignore: avoid_print
      print('[Repo] streamRecording called with empty id');
      return const Stream<Map<String, dynamic>?>.empty();
    }
    return supa
        .from('recordings')
        .stream(primaryKey: ['id'])
        .eq('id', recordingId)
        .limit(1)
        .map((rows) => rows.isNotEmpty ? rows.first as Map<String, dynamic> : null);
  }

  // Read one summary for this recording (may be null while processing)
  Future<Map<String, dynamic>?> getSummaryByRecording(String recordingId) async {
    if (recordingId.isEmpty) {
      // ignore: avoid_print
      print('[Repo] getSummaryByRecording called with empty id');
      return null;
    }
    // Security handled by RLS (checks recording ownership)
    // Order by created_at desc and limit to 1 to get most recent summary
    final res = await supa
        .from('summaries')
        .select()
        .eq('recording_id', recordingId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  // Convenience: fetch single recording once (for storage_path, etc.)
  Future<Map<String, dynamic>?> getRecording(String recordingId) async {
    if (recordingId.isEmpty) {
      // ignore: avoid_print
      print('[Repo] getRecording called with empty id');
      return null;
    }
    final userId = await AuthX.requireUserId();
    final res = await supa
        .from('recordings')
        .select('id, user_id, storage_path, status, created_at, run_id')
        .eq('id', recordingId)
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  // ---------- Optional: user notes ----------
  Stream<List<Map<String, dynamic>>> streamNotes(String recordingId) {
    return supa
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('recording_id', recordingId)
        .order('created_at', ascending: false)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  Future<void> addNote(String recordingId, String text) async {
    final userId = await AuthX.requireUserId();
    await supa.from('notes').insert({
      'user_id': userId,
      'recording_id': recordingId,
      'text': text,
    });
  }
}