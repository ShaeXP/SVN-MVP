// lib/services/pipeline.dart
import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import 'auth.dart';
import 'status_transition_service.dart';
import 'logger.dart';

/// Production pipeline wired to your Edge Functions:
/// - sv_init_note_run
/// - sv_start_asr_job_user  (fallback: sv_start_asr_job)
/// - sv_list_runs
/// - sv_get_run
///
/// Uploads audio directly to Storage, updates DB, then invokes ASR.
class Pipeline {
  // â”€â”€ Configure to match your project â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String bucket = 'recordings'; // your Storage bucket
  static const String runsTable = 'note_runs'; // your Postgres table
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // Edge Function names (from your list)
  static const String _fnInitRun = 'sv_init_note_run';
  static const String _fnStartAsrUser = 'sv_start_asr_job_user';
  static const String _fnStartAsrAdmin = 'sv_start_asr_job';
  static const String _fnListRuns = 'sv_list_runs';
  static const String _fnGetRun = 'sv_get_run';

  final SupabaseClient _sp = Supa.client;

  // â”€â”€ Primary flow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// 1) Create a run row via edge function; returns run id.
  Future<String> initRun() async {
    try {
      final res = await _sp.functions.invoke(
        'sv_init_note_run',
        body: const {}, // keep whatever you were sending
      );

      debugPrint('sv_init_note_run status=${res.status}');
      debugPrint(
          'sv_init_note_run data=${res.data}'); // <-- we need to see this

      final data = (res.data is Map) ? res.data as Map : const {};
      final runId = (data['run_id'] ?? data['id'] ?? data['runId'])?.toString();

      if (runId == null || runId.isEmpty) {
        throw Exception(
            'sv_init_note_run returned no run id. Raw: ${res.data}');
      }
      return runId;
    } catch (e, st) {
      debugPrint('initRun error: $e\n$st');
      rethrow;
    }
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

  // â”€â”€ Convenience for library/details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Internal helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // ── Summarizer toggle ───────────────────────────────────────────────────────
  // Uses Env.SUMMARY_ENGINE from env.dart
  // ───────────────────────────────────────────────────────────────────────────

  /// Summarize a recording using the configured engine
  static Future<void> summarizeRecording(String recordingId) async {
    final userId = await AuthX.requireUserId();
    
    try {
      logx('[PIPELINE] Starting summarization for recordingId: $recordingId, engine: ${Env.SUMMARY_ENGINE}', tag: 'PIPELINE');
      
      if (Env.SUMMARY_ENGINE == 'openai') {
        final supabase = Supabase.instance.client;
        // Read preferred summary style (default quick_recap)
        String style = 'quick_recap';
        try {
          // SharedPreferences is optional in this context; swallow errors
          // to preserve existing behavior on any platform issues.
          final prefs = await SharedPreferences.getInstance();
          style = prefs.getString('summarize_style') ?? 'quick_recap';
        } catch (_) {}
        final resp = await supabase.functions.invoke('sv_summarize_openai', body: { 
          'recordingId': recordingId,
          // Accept both notations defensively
          'summary_style': style,
          'summaryStyle': style,
        });
        if (resp.data == null || resp.status != 200) {
          throw Exception('sv_summarize_openai failed: ${resp.data}');
        }
        
        // Handle successful completion
        await StatusTransitionService.handleSummarizationComplete(
          recordingId: recordingId,
          success: true,
        );
        
      } else {
        // existing summarize-lite path
        await _summarizeLite(recordingId, userId);
        
        // Handle successful completion
        await StatusTransitionService.handleSummarizationComplete(
          recordingId: recordingId,
          success: true,
        );
      }
      
      logx('[PIPELINE] Summarization completed successfully for recordingId: $recordingId', tag: 'PIPELINE');
      
    } catch (e) {
      logx('[PIPELINE] Summarization failed for recordingId: $recordingId', tag: 'PIPELINE', error: e);
      
      // Handle error completion
      await StatusTransitionService.handleSummarizationComplete(
        recordingId: recordingId,
        success: false,
        errorMessage: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Handle transcription completion and trigger summarization
  static Future<void> handleTranscriptionComplete({
    required String recordingId,
    required String transcriptId,
  }) async {
    await StatusTransitionService.handleTranscriptionComplete(
      recordingId: recordingId,
      transcriptId: transcriptId,
    );
  }

  /// Lightweight summarization fallback
  static Future<void> _summarizeLite(String recordingId, String userId) async {
    // TODO: Implement lite summarization logic
    // This would call the existing summarize-lite function
    debugPrint('Lite summarization not yet implemented for recording: $recordingId');
  }
}
