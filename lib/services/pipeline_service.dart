import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/data/recording_repo.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/presentation/settings_screen/controller/settings_controller.dart';
import '../utils/auth_guard.dart';
import '../env.dart';

class PipelineService {
  final supa = Supabase.instance.client;

  Future<Map<String, String>> run(String localPath, {String? storagePath, String? contentType, bool providedTranscript = false, String? transcriptText}) async {
    try {
      final session = AuthGuard.requireSession();
      final user = session.user;

      final now = DateTime.now();
      final recordingId = const Uuid().v4();
      final bucket = 'recordings'; // Use recordings bucket
      final y = '${now.year}';
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');

      String? fullStoragePath;
      String? contentType;

      if (providedTranscript) {
        // Transcript-only upload - no storage needed
        debugPrint('[SVN][TRANSCRIPT] processing transcript-only upload');
        fullStoragePath = null;
        contentType = contentType ?? 'text/plain';
      } else {
        // Audio file upload
        final objectPath = '${user.id}/$y/$m/$d/$recordingId.m4a';
        final bytes = await File(localPath).readAsBytes();
        await supa.storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'audio/m4a',
            upsert: true,
            cacheControl: '3600',
          ),
        );
        debugPrint('[SVN][UPLOAD] ok object=$objectPath bytes=${bytes.length}');
        fullStoragePath = 'recordings/$objectPath';
        contentType = contentType ?? 'audio/m4a';
      }

      // 2) Upsert recording row BEFORE function call (satisfy FK)
      final insertPayload = {
        'id': recordingId,
        'user_id': user.id,
        'storage_path': fullStoragePath,
      };
      final recResp = await supa.from('recordings').upsert(insertPayload).select('id').limit(1);
      if (recResp.isEmpty) {
        throw Exception('Failed to create recording row');
      }
      debugPrint('[SVN][DB] recordings upsert ok id=$recordingId');

      // 2.5) Store transcript if provided
      if (providedTranscript && transcriptText != null && transcriptText.isNotEmpty) {
        try {
          // Try transcripts table first
          await supa.from('transcripts').insert({
            'recording_id': recordingId,
            'text': transcriptText,
            'origin': 'upload',
          });
          debugPrint('[SVN][TRANSCRIPT] stored in transcripts table');
        } catch (e) {
          // Fallback to recordings.transcript_text
          try {
            await supa.from('recordings').update({'transcript_text': transcriptText}).eq('id', recordingId);
            debugPrint('[SVN][TRANSCRIPT] stored in recordings.transcript_text');
          } catch (e2) {
            debugPrint('[SVN][TRANSCRIPT] failed to store transcript: $e2');
            // Continue anyway - transcript will be passed to function
          }
        }
      }

      // 3) Get settings preferences
      final settings = Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>()
          : null;

      // 4) Invoke pipeline function with preferences
      debugPrint('[SVN][PIPELINE] recordingId=$recordingId storagePath=$fullStoragePath fn=sv_run_pipeline demo=${Env.demoMode}');
      final body = {
        if (fullStoragePath != null) 'storage_path': fullStoragePath,
        'recording_id': recordingId,
        'content_type': contentType,
        'provided_transcript': providedTranscript,
        if (transcriptText != null) 'transcript_text': transcriptText,
        if (settings != null) 'prefs': {
          'normalize_audio': settings.normalizeAudio.value,
          'auto_trim_silence': settings.autoTrimSilence.value,
          'language_hint': settings.languageHint.value,         // 'auto' or ISO code
          'summarize_style': settings.summarizeStyle.value,
          'auto_email': settings.autoSendEmail.value,
        },
        if (settings != null) 'privacy': {
          'analytics_opt_in': settings.analyticsOptIn.value,
          'crash_opt_in': settings.crashOptIn.value,
          'redact_pii': settings.redactPII.value,
          'retention_days': settings.dataRetentionDays.value,   // 0 = keep forever
        },
        'demo': Env.demoMode,
      };
      
      final resp = await supa.functions.invoke('sv_run_pipeline', body: body);

      if (resp.status != 200) {
        final errorMsg = resp.data is Map ? (resp.data['message']?.toString() ?? '') : resp.data?.toString() ?? '';
        throw Exception('Function error (${resp.status}): ${errorMsg.isEmpty ? "No error message" : errorMsg}');
      }

      final data = resp.data;
      String? summaryId;
      String? runId;
      if (data is Map) {
        summaryId = (data['summary_id'] ?? data['id'] ?? data['summaryId'])?.toString();
        runId = data['runId']?.toString(); // Parse runId from edge function response
        final ok = (data['ok'] == true);
        if (summaryId == null && ok) {
          debugPrint('[SVN][PIPELINE] no summary in resp, polling summaries for recording_id=$recordingId');
          summaryId = await _waitForSummaryId(recordingId);
        }
      } else if (data is String) {
        summaryId = data;
      }
      if (summaryId == null) {
        throw Exception('Function returned no summary id: $data');
      }

      return {
        'recordingId': recordingId,
        'summaryId': summaryId,
        if (runId != null) 'runId': runId, // Include runId if available
      };
    } catch (e, st) {
      debugPrint('[SVN][PIPELINE] ERROR: $e\n$st');
      rethrow;
    }
  }

  Future<String> _waitForSummaryId(String recordingId, {Duration timeout = const Duration(seconds: 25), Duration interval = const Duration(seconds: 1)}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      final rows = await supa
          .from('summaries')
          .select('id')
          .eq('recording_id', recordingId)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        final id = rows.first['id']?.toString();
        if (id != null && id.isNotEmpty) {
          debugPrint('[SVN][WAIT] summary found id=$id');
          return id;
        }
      }

      await Future.delayed(interval);
    }
    throw Exception('Timed out waiting for summary for recording_id=$recordingId');
  }

  Future<String> runWithId(String storagePath, String recordingId, {String? runId}) async {
    final body = {'storage_path': storagePath, 'recording_id': recordingId};
    if (runId != null) body['run_id'] = runId;
    final resp = await supa.functions.invoke('sv_process_upload', body: body);
    if (resp.data is Map && resp.data['run_id'] != null) return resp.data['run_id'].toString();
    return 'started';
  }

  // NEW: simple re-run by recording id (reads storage_path then invokes)
  Future<String> rerunByRecordingId(String recordingId) async {
    final repo = RecordingRepo();
    final row = await repo.getRecording(recordingId);
    if (row == null) throw Exception('Recording not found');
    
    var storagePath = (row['storage_path'] ?? '').toString().trim();
    if (storagePath.isEmpty) throw Exception('storage_path missing');
    
    // Ensure path starts with bucket name
    if (!storagePath.startsWith('recordings/')) {
      // If it doesn't have the prefix, add it
      storagePath = 'recordings/$storagePath';
    }
    
    // Use sv_run_pipeline which saves transcripts properly
    final resp = await supa.functions.invoke(
      'sv_run_pipeline',
      body: {
        'storage_path': storagePath,
        'recording_id': recordingId,
      },
    );
    
    if (resp.status != 200) {
      final err = resp.data is Map ? (resp.data['message']?.toString() ?? '') : resp.data?.toString() ?? '';
      throw Exception('Pipeline failed (${resp.status}): ${err.isEmpty ? "No error" : err}');
    }
    
    if (resp.data is Map && resp.data['trace'] != null) {
      return resp.data['trace'].toString();
    }
    return 'started';
  }
}
