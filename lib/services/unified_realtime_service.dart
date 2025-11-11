import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../domain/recordings/recording_status.dart';
import '../controllers/recording_state_coordinator.dart';
import 'logger.dart';

/// Unified realtime service that handles status updates from Supabase
/// Subscribes to recordings table changes and dispatches to state coordinator
class UnifiedRealtimeService extends GetxService {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _currentRecordingId;
  Timer? _fallbackTimer;

  /// Start watching a recording for status changes
  Future<void> watchRecording(String recordingId, {String? traceId}) async {
    // Stop any existing subscription
    await stopWatching();

    _currentRecordingId = recordingId;
    
    // Get the state coordinator
    final coordinator = Get.find<RecordingStateCoordinator>();
    coordinator.startTracking(recordingId, traceId: traceId);

    // Set up realtime subscription
    _channel = _client.channel('recording_$recordingId');
    
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'recordings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: recordingId,
      ),
      callback: _handleStatusUpdate,
    );

    // Subscribe to the channel
    await _channel!.subscribe();

    // Set up fallback polling as backup
    _startFallbackPolling(recordingId);

    logx('[REALTIME] started watching recording=$recordingId', tag: 'REALTIME');
  }

  /// Stop watching the current recording
  Future<void> stopWatching() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
    
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    
    _currentRecordingId = null;
    
    logx('[REALTIME] stopped watching', tag: 'REALTIME');
  }

  /// Handle status update from realtime subscription
  void _handleStatusUpdate(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final statusString = newRecord['status'] as String?;
      final summaryId = newRecord['summary_id'] as String?;
      final traceId = newRecord['trace_id'] as String?;

      // Convert string to enum
      final status = RecordingStatus.fromString(statusString);
      
      logx('[REALTIME] recording=${_currentRecordingId} status=${status.name}', tag: 'REALTIME');

      // Get the state coordinator and dispatch the status
      final coordinator = Get.find<RecordingStateCoordinator>();
      coordinator.dispatch(status, traceId: traceId);
      
      // Bridge to UI state
      coordinator.onBackendStatus(_currentRecordingId!, status);

      // Handle navigation when ready
      if (status == RecordingStatus.ready) {
        _handleReadyState(summaryId);
      }

    } catch (e) {
      logx('[REALTIME] error handling update: $e', tag: 'REALTIME');
    }
  }

  /// Handle ready state - navigate to summary screen
  void _handleReadyState(String? summaryId) {
    try {
      // Import routes dynamically to avoid circular dependencies
      // This should navigate to the summary screen
      logx('[REALTIME] recording ready, summaryId=$summaryId', tag: 'REALTIME');
      
      // TODO: Add navigation logic here
      // Get.offNamed(Routes.recordingSummaryScreen, arguments: {
      //   'summaryId': summaryId,
      //   'recordingId': _currentRecordingId,
      // });
      
    } catch (e) {
      logx('[REALTIME] error handling ready state: $e', tag: 'REALTIME');
    }
  }

  /// Start fallback polling as backup for realtime
  void _startFallbackPolling(String recordingId) {
    _fallbackTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // Check if channel is still connected (simplified check)
        if (_channel == null) {
          logx('[REALTIME] channel disconnected, attempting reconnection', tag: 'REALTIME');
          await watchRecording(recordingId);
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
          
          final coordinator = Get.find<RecordingStateCoordinator>();
          if (coordinator.currentStatus != status) {
            logx('[REALTIME] fallback poll detected status change: ${coordinator.currentStatus} → $status', tag: 'REALTIME');
            coordinator.dispatch(status);
            coordinator.onBackendStatus(recordingId, status);
          }
        }

      } catch (e) {
        logx('[REALTIME] fallback poll error: $e', tag: 'REALTIME');
      }
    });
  }

  @override
  void onClose() {
    stopWatching();
    super.onClose();
  }
}
