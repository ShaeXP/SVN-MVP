import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pipeline_progress.dart';
import '../feature_flags.dart';

class PipelineProgressEvent {
  final PipelineProgress progress;
  final String? summaryId;
  
  PipelineProgressEvent(this.progress, {this.summaryId});
}

class PipelineProgressService {
  final _client = Supabase.instance.client;

  Stream<PipelineProgressEvent> watchRecording(String recordingId) async* {
    if (!ProgressUI.enabled) return;
    
    // Fetch initial state
    final initial = await _client
        .from('recordings')
        .select('status, summary_id')
        .eq('id', recordingId)
        .maybeSingle();
    
    if (initial != null) {
      yield PipelineProgressEvent(
        PipelineProgress.fromStatus(initial['status'] as String? ?? 'local'),
        summaryId: initial['summary_id'] as String?,
      );
    }

    // Use the stream method for realtime updates
    yield* _client
        .from('recordings')
        .stream(primaryKey: ['id'])
        .eq('id', recordingId)
        .map((data) {
          if (data.isNotEmpty) {
            final record = data.first;
            final status = record['status'] as String? ?? 'local';
            final summaryId = record['summary_id'] as String?;
            return PipelineProgressEvent(
              PipelineProgress.fromStatus(status),
              summaryId: summaryId,
            );
          }
          return PipelineProgressEvent(
            PipelineProgress.fromStatus('local'),
          );
        });
  }
}
