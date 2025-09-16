// lib/services/pipeline.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Production pipeline wired to your Edge Functions:
/// - sv_init_note_run
/// - sv_start_asr_job_user  (fallback: sv_start_asr_job)
/// - sv_list_runs
/// - sv_get_run
///
/// Uploads audio directly to Storage, updates DB, then invokes ASR.
class Pipeline {
  // ── Configure to match your project ─────────────────────────────────────────
  static const String bucket = 'recordings'; // your Storage bucket
  static const String runsTable = 'note_runs'; // your Postgres table
  // ────────────────────────────────────────────────────────────────────────────

  // Edge Function names (from your list)
  static const String _fnInitRun = 'sv_init_note_run';
  static const String _fnStartAsrUser = 'sv_start_asr_job_user';
  static const String _fnStartAsrAdmin = 'sv_start_asr_job';
  static const String _fnListRuns = 'sv_list_runs';
  static const String _fnGetRun = 'sv_get_run';

  final SupabaseClient _sp = SupabaseService.instance.client;

  // ── Primary flow ────────────────────────────────────────────────────────────

  /// 1) Create a run row via edge function; returns run id.
  Future<String> initRun({String? title}) async {
    final user = _sp.auth.currentUser;
    if (user == null) throw Exception('Not signed in.');

    final res = await _invoke(
      _fnInitRun,
      body: {if (title != null && title.isNotEmpty) 'title': title},
    );

    final data = res.data;
    if (data is Map) {
      final id = (data['run_id'] ?? data['id'] ?? data['runId'] ?? data['uuid'])
          ?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    throw Exception('sv_init_note_run returned no run id.');
  }

  /// 2) Upload audio bytes to Storage. Returns public URL if bucket is public,
  /// otherwise returns the path (set storePublicUrl=false).
  Future<String> uploadAudioBytes({
    required String path, // e.g. 'user/<uid>/<run>.m4a'
    required List<int> bytes,
    required String contentType, // e.g. 'audio/mpeg'
    bool upsert = true,
    bool storePublicUrl = true,
  }) async {
    final storage = _sp.storage.from(bucket);

    await storage.uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: contentType, upsert: upsert),
    );

    return storePublicUrl ? storage.getPublicUrl(path) : path;
  }

  /// 3) Update the run row with audio reference + duration.
  Future<void> insertRecording({
    required String runId,
    required String storagePathOrUrl,
    required int durationMs,
  }) async {
    final update = <String, dynamic>{
      'audio_url': storagePathOrUrl, // URL or path
      'duration_s': (durationMs / 1000).floor(),
      'status': 'uploaded',
    };

    final resp = await _sp.from(runsTable).update(update).eq('id', runId);
    if (resp is Map && resp['error'] != null) {
      throw Exception('insertRecording failed: ${resp['error']}');
    }
  }

  /// 4) Kick off ASR via user-scoped function; fallback to admin variant.
  Future<void> startAsr(String runId, String audioRef) async {
    final tryUser = await _tryInvoke(
      _fnStartAsrUser,
      body: {'run_id': runId, 'audio_url': audioRef},
    );
    if (tryUser == null) {
      final admin = await _invoke(
        _fnStartAsrAdmin,
        body: {'run_id': runId, 'audio_url': audioRef},
      );
      if (admin.data == null && admin.status != 200) {
        throw Exception('sv_start_asr_job failed with status ${admin.status}');
      }
    }
    await _sp.from(runsTable).update({'status': 'processing'}).eq('id', runId);
  }

  // ── Convenience for library/details ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listRuns({int limit = 50}) async {
    final res = await _invoke(_fnListRuns, body: {'limit': limit});
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['runs'] is List) {
      return (data['runs'] as List).cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> getRun(String runId) async {
    final res = await _invoke(_fnGetRun, body: {'run_id': runId});
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  Future<FunctionResponse> _invoke(String fn,
      {Map<String, dynamic>? body}) async {
    final resp = await _sp.functions.invoke(fn, body: body ?? const {});
    if (resp.status >= 400) {
      throw Exception('$fn failed (${resp.status}): ${resp.data}');
    }
    return resp;
  }

  Future<FunctionResponse?> _tryInvoke(String fn,
      {Map<String, dynamic>? body}) async {
    try {
      return await _invoke(fn, body: body);
    } catch (_) {
      return null;
    }
  }

  /// Get signed upload URL for direct storage uploads
  Future<String> signUpload(String storagePath) async {
    final storage = _sp.storage.from(bucket);

    // Generate signed URL for uploading
    final signedUrl = await storage.createSignedUploadUrl(storagePath);
    return signedUrl.signedUrl;
  }
}