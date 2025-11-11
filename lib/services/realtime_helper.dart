import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../domain/recordings/recording_status.dart';
import '../controllers/recording_state_coordinator.dart';
import 'logger.dart';

/// Reusable helper for proper Realtime subscription to recording status changes
/// Ensures correct Postgres Changes subscription with proper cleanup
class RealtimeHelper {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Map<String, RealtimeChannel> _channels = {};
  static final Map<String, Timer> _fallbackTimers = {};

  /// Wire a recording channel for realtime status updates
  /// Returns the channel for manual cleanup if needed
  static RealtimeChannel wireRecordingChannel(String recordingId) {
    // Clean up any existing channel for this recording
    _cleanupChannel(recordingId);

    final channel = _client.channel('rec_$recordingId');
    
    // Subscribe to Postgres Changes on the recordings table
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'recordings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: recordingId,
      ),
      callback: (payload) {
        logx('[REALTIME] received payload for rec_$recordingId: $payload', tag: 'REALTIME');
        
        final newRecord = payload.newRecord;
        final statusString = newRecord['status'] as String?;
        final traceId = newRecord['trace_id'] as String?;
        
        logx('[REALTIME] parsed status=$statusString, traceId=$traceId', tag: 'REALTIME');
        
        // Convert string to enum
        final status = RecordingStatus.fromString(statusString);
        
        logx('[REALTIME] subscribed rec_$recordingId status=${status.name}', tag: 'REALTIME');
        
        // Get coordinator and dispatch status
        try {
          final coordinator = Get.find<RecordingStateCoordinator>();
          coordinator.dispatch(status, traceId: traceId);
          coordinator.onBackendStatus(recordingId, status);
          logx('[REALTIME] coordinator updated successfully', tag: 'REALTIME');
        } catch (e) {
          logx('[REALTIME] coordinator not found: $e', tag: 'REALTIME', error: e);
        }
      },
    );

    // Add basic logging for channel events
    logx('[REALTIME] subscribing to recording=$recordingId', tag: 'REALTIME');

    // Subscribe to the channel
    channel.subscribe();
    _channels[recordingId] = channel;
    
    logx('[REALTIME] subscribing to recording=$recordingId', tag: 'REALTIME');
    
    // Start fallback polling as backup
    _startFallbackPolling(recordingId);
    
    return channel;
  }

  /// Clean up a specific recording channel
  static void cleanupChannel(String recordingId) {
    _cleanupChannel(recordingId);
  }

  /// Clean up all channels
  static void cleanupAll() {
    for (final recordingId in _channels.keys.toList()) {
      _cleanupChannel(recordingId);
    }
  }

  /// Internal cleanup method
  static void _cleanupChannel(String recordingId) {
    // Remove channel
    final channel = _channels.remove(recordingId);
    if (channel != null) {
      _client.removeChannel(channel);
      logx('[REALTIME] unsubscribed from recording=$recordingId', tag: 'REALTIME');
    }
    
    // Cancel fallback timer
    _fallbackTimers[recordingId]?.cancel();
    _fallbackTimers.remove(recordingId);
  }

  /// Start fallback polling as backup for realtime
  static void _startFallbackPolling(String recordingId) {
    _fallbackTimers[recordingId]?.cancel();
    
    _fallbackTimers[recordingId] = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // Check if channel is still connected
        final channel = _channels[recordingId];
        if (channel == null) {
          logx('[REALTIME] channel not found, stopping fallback polling', tag: 'REALTIME');
          timer.cancel();
          return;
        }

        // Poll current status as backup
        final response = await _client
            .from('recordings')
            .select('status, summary_id, trace_id')
            .eq('id', recordingId)
            .maybeSingle();

        if (response != null) {
          final statusString = response['status'] as String?;
          final status = RecordingStatus.fromString(statusString);
          final traceId = response['trace_id'] as String?;
          
          logx('[REALTIME] fallback poll: recording=$recordingId status=${status.name}', tag: 'REALTIME');
          
          try {
            final coordinator = Get.find<RecordingStateCoordinator>();
            coordinator.dispatch(status, traceId: traceId);
            coordinator.onBackendStatus(recordingId, status);
          } catch (e) {
            logx('[REALTIME] fallback coordinator error: $e', tag: 'REALTIME', error: e);
          }
        }

      } catch (e) {
        logx('[REALTIME] fallback poll error: $e', tag: 'REALTIME', error: e);
      }
    });
  }

  /// Query initial status and seed UI
  static Future<void> seedInitialStatus(String recordingId) async {
    try {
      final response = await _client
          .from('recordings')
          .select('status, summary_id, trace_id')
          .eq('id', recordingId)
          .maybeSingle();

      if (response != null) {
        final statusString = response['status'] as String?;
        final status = RecordingStatus.fromString(statusString);
        final traceId = response['trace_id'] as String?;
        
        logx('[REALTIME] initial status: recording=$recordingId status=${status.name}', tag: 'REALTIME');
        
        try {
          final coordinator = Get.find<RecordingStateCoordinator>();
          coordinator.dispatch(status, traceId: traceId);
          coordinator.onBackendStatus(recordingId, status);
        } catch (e) {
          logx('[REALTIME] initial coordinator error: $e', tag: 'REALTIME', error: e);
        }
      }
    } catch (e) {
      logx('[REALTIME] initial status error: $e', tag: 'REALTIME', error: e);
    }
  }
}
