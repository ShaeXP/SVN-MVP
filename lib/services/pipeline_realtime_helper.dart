import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../domain/recordings/recording_status.dart';
import '../domain/recordings/pipeline_view_state.dart';
import 'logger.dart';

class PipelineRealtimeHelper {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Map<String, RealtimeChannel> _channels = {};
  static final Map<String, Timer> _fallbackTimers = {};
  static final Map<String, int> _lastSteps = {};

  /// Wire a Realtime channel for a specific pipeline run
  static RealtimeChannel wireRunChannel(String runId) {
    _cleanupChannel(runId); // Ensure no duplicate subscriptions

    final channel = _client.channel('run_$runId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'pipeline_runs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: runId,
      ),
      callback: (payload) {
        logx('[PIPELINE_REALTIME] received payload for run_$runId: $payload', tag: 'PIPELINE_REALTIME');
        
        final newRecord = payload.newRecord;
        final stage = newRecord['stage'] as String?;
        final progress = (newRecord['progress'] as num?)?.toDouble();
        final step = (newRecord['step'] as int?) ?? 0;
        final message = newRecord['message'] as String?;
        // final traceId = newRecord['trace_id'] as String?;
        
        logx('[PIPELINE_REALTIME] parsed stage=$stage, progress=$progress, step=$step, message=$message', tag: 'PIPELINE_REALTIME');
        
        // Ignore out-of-order updates
        if (step < (_lastSteps[runId] ?? 0)) {
          logx('[PIPELINE_REALTIME] ignoring out-of-order update: step=$step < lastStep=${_lastSteps[runId]}', tag: 'PIPELINE_REALTIME');
          return;
        }
        _lastSteps[runId] = step;
        
        // Map stage to RecordingStatus
        final status = _mapStageToStatus(stage);
        
        logx('[PIPELINE_REALTIME] mapped stage=$stage → status=${status.name}', tag: 'PIPELINE_REALTIME');
        
        try {
          // Update PipelineRx if it exists
          if (Get.isRegistered<PipelineRx>(tag: 'pipe_$runId')) {
            final rx = Get.find<PipelineRx>(tag: 'pipe_$runId');
            rx.setState(
              status,
              p: progress ?? _getDefaultProgress(status),
              key: stage ?? 'unknown',
              showProgress: true,
            );
            logx('[PIPELINE_REALTIME] PipelineRx updated successfully', tag: 'PIPELINE_REALTIME');
          } else {
            logx('[PIPELINE_REALTIME] PipelineRx not found for run_$runId', tag: 'PIPELINE_REALTIME');
          }
        } catch (e) {
          logx('[PIPELINE_REALTIME] PipelineRx update error: $e', tag: 'PIPELINE_REALTIME', error: e);
        }
      },
    );

    // Channel lifecycle events (simplified for Supabase Flutter)
    // Note: Supabase Flutter doesn't expose the same channel events as the JS client
    // We'll rely on the subscription callback and fallback polling for status

    logx('[PIPELINE_REALTIME] subscribing to run=$runId', tag: 'PIPELINE_REALTIME');

    channel.subscribe();
    _channels[runId] = channel;
    
    _startFallbackPolling(runId);
    
    return channel;
  }

  /// Start fallback polling for when Realtime is disconnected
  static void _startFallbackPolling(String runId) {
    _fallbackTimers[runId]?.cancel(); // Cancel existing timer
    _fallbackTimers[runId] = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // Check if channel exists and is active (simplified check)
        if (!_channels.containsKey(runId)) {
          logx('[PIPELINE_REALTIME] fallback poll: channel not subscribed, attempting re-subscribe for $runId', tag: 'PIPELINE_REALTIME');
          wireRunChannel(runId); // Re-subscribe
          return;
        }

        final response = await _client
            .from('pipeline_runs')
            .select('stage, progress, step, message, trace_id')
            .eq('id', runId)
            .maybeSingle();

        if (response != null) {
          final stage = response['stage'] as String?;
          final progress = (response['progress'] as num?)?.toDouble();
          final step = (response['step'] as int?) ?? 0;
          // final message = response['message'] as String?;
          // final traceId = response['trace_id'] as String?;
          
          logx('[PIPELINE_REALTIME] fallback poll: run=$runId stage=$stage progress=$progress step=$step', tag: 'PIPELINE_REALTIME');
          
          // Ignore out-of-order updates
          if (step < (_lastSteps[runId] ?? 0)) {
            return;
          }
          _lastSteps[runId] = step;
          
          final status = _mapStageToStatus(stage);
          
          try {
            if (Get.isRegistered<PipelineRx>(tag: 'pipe_$runId')) {
              final rx = Get.find<PipelineRx>(tag: 'pipe_$runId');
              if (rx.status.value != status || rx.progress.value != (progress ?? _getDefaultProgress(status))) {
                logx('[PIPELINE_REALTIME] fallback poll detected change: ${rx.status.value} → $status', tag: 'PIPELINE_REALTIME');
                rx.setState(
                  status,
                  p: progress ?? _getDefaultProgress(status),
                  key: stage ?? 'unknown',
                  showProgress: true,
                );
              }
            }
          } catch (e) {
            logx('[PIPELINE_REALTIME] fallback poll PipelineRx error: $e', tag: 'PIPELINE_REALTIME', error: e);
          }
        }

      } catch (e) {
        logx('[PIPELINE_REALTIME] fallback poll error: $e', tag: 'PIPELINE_REALTIME', error: e);
      }
    });
  }

  /// Seed initial state from the current pipeline run
  static Future<void> seedInitialState(String runId) async {
    try {
      final response = await _client
          .from('pipeline_runs')
          .select('stage, progress, step, message, trace_id')
          .eq('id', runId)
          .maybeSingle();

      if (response != null) {
        final stage = response['stage'] as String?;
        final progress = (response['progress'] as num?)?.toDouble();
        final step = (response['step'] as int?) ?? 0;
        // final message = response['message'] as String?;
        // final traceId = response['trace_id'] as String?;
        
        logx('[PIPELINE_REALTIME] initial state: run=$runId stage=$stage progress=$progress step=$step', tag: 'PIPELINE_REALTIME');
        
        _lastSteps[runId] = step;
        
        final status = _mapStageToStatus(stage);
        
        try {
          if (Get.isRegistered<PipelineRx>(tag: 'pipe_$runId')) {
            final rx = Get.find<PipelineRx>(tag: 'pipe_$runId');
            rx.setState(
              status,
              p: progress ?? _getDefaultProgress(status),
              key: stage ?? 'unknown',
              showProgress: true,
            );
          }
        } catch (e) {
          logx('[PIPELINE_REALTIME] initial PipelineRx error: $e', tag: 'PIPELINE_REALTIME', error: e);
        }
      }
    } catch (e) {
      logx('[PIPELINE_REALTIME] initial state error: $e', tag: 'PIPELINE_REALTIME', error: e);
    }
  }

  /// Clean up channel and timer for a specific run
  static void cleanupChannel(String runId) {
    _cleanupChannel(runId);
  }

  static void _cleanupChannel(String runId) {
    if (_channels.containsKey(runId)) {
      _client.removeChannel(_channels[runId]!);
      _channels.remove(runId);
      logx('[PIPELINE_REALTIME] removed channel for run=$runId', tag: 'PIPELINE_REALTIME');
    }
    if (_fallbackTimers.containsKey(runId)) {
      _fallbackTimers[runId]?.cancel();
      _fallbackTimers.remove(runId);
      logx('[PIPELINE_REALTIME] cancelled fallback timer for run=$runId', tag: 'PIPELINE_REALTIME');
    }
    _lastSteps.remove(runId);
  }

  /// Map pipeline stage to RecordingStatus
  static RecordingStatus _mapStageToStatus(String? stage) {
    switch (stage?.toLowerCase()) {
      case 'queued':
        return RecordingStatus.uploading; // Map queued to uploading for UI
      case 'uploading':
        return RecordingStatus.uploading;
      case 'transcribing':
        return RecordingStatus.transcribing;
      case 'summarizing':
        return RecordingStatus.summarizing;
      case 'ready':
        return RecordingStatus.ready;
      case 'error':
        return RecordingStatus.error;
      default:
        return RecordingStatus.error;
    }
  }

  /// Get default progress for a status
  static double _getDefaultProgress(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.local:
        return 0.0;
      case RecordingStatus.uploading:
        return 0.15;
      case RecordingStatus.transcribing:
        return 0.45;
      case RecordingStatus.summarizing:
        return 0.75;
      case RecordingStatus.ready:
        return 1.0;
      case RecordingStatus.error:
        return 0.0;
    }
  }
}
