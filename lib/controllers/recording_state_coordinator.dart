import 'package:get/get.dart';
import '../domain/recordings/recording_status.dart';
import '../domain/recordings/pipeline_view_state.dart';
import '../ui/status/status_theme.dart';
import '../services/logger.dart';

/// Recording state coordinator with strict state machine logic
/// Handles status transitions and validates state changes
class RecordingStateCoordinator extends GetxController {
  final _currentStatus = RecordingStatus.local.obs;
  final _isVisible = false.obs;
  final _hasError = false.obs;
  final _traceId = ''.obs;

  // Getters
  RecordingStatus get currentStatus => _currentStatus.value;
  bool get isVisible => _isVisible.value;
  bool get hasError => _hasError.value;
  String get traceId => _traceId.value;
  
  // Computed properties
  StatusTheme get currentTheme => StatusTheme.forStatus(currentStatus);
  bool get isTerminal => currentStatus.isTerminal;
  bool get isProcessing => currentStatus.isProcessing;

  // State machine transition rules
  static const Map<RecordingStatus, List<RecordingStatus>> _validTransitions = {
    RecordingStatus.local: [RecordingStatus.uploading],
    RecordingStatus.uploading: [RecordingStatus.transcribing, RecordingStatus.error],
    RecordingStatus.transcribing: [RecordingStatus.summarizing, RecordingStatus.error],
    RecordingStatus.summarizing: [RecordingStatus.ready, RecordingStatus.error],
    RecordingStatus.ready: [], // Terminal state
    RecordingStatus.error: [], // Terminal state
  };

  /// Dispatch a new status - validates transition and updates state
  void dispatch(RecordingStatus newStatus, {String? traceId}) {
    if (traceId != null) {
      _traceId.value = traceId;
    }

    final current = _currentStatus.value;
    
    // Log the transition attempt
    logx('[PIPELINE][${_traceId.value}] status=$current → $newStatus', tag: 'PIPELINE');

    // Validate transition
    if (!_isValidTransition(current, newStatus)) {
      logx('[PIPELINE][${_traceId.value}] invalid transition $current → $newStatus, coercing to error', tag: 'PIPELINE');
      _coerceToError('Invalid transition: $current → $newStatus');
      return;
    }

    // Update state
    _currentStatus.value = newStatus;
    _hasError.value = newStatus == RecordingStatus.error;
    _isVisible.value = newStatus != RecordingStatus.local;

    // Log successful transition
    logx('[PIPELINE][${_traceId.value}] status=$newStatus', tag: 'PIPELINE');
  }

  /// Start tracking a recording with initial status
  void startTracking(String recordingId, {String? traceId}) {
    _traceId.value = traceId ?? '';
    _currentStatus.value = RecordingStatus.local;
    _isVisible.value = false;
    _hasError.value = false;
    
    logx('[PIPELINE][${_traceId.value}] started tracking recording=$recordingId', tag: 'PIPELINE');
  }

  /// Stop tracking and reset to initial state
  void stopTracking() {
    _currentStatus.value = RecordingStatus.local;
    _isVisible.value = false;
    _hasError.value = false;
    _traceId.value = '';
    
    logx('[PIPELINE] stopped tracking', tag: 'PIPELINE');
  }

  /// Force error state with reason
  void forceError(String reason) {
    _coerceToError(reason);
  }

  /// Check if transition is valid according to state machine
  bool _isValidTransition(RecordingStatus from, RecordingStatus to) {
    // Same status is always valid (idempotent)
    if (from == to) return true;
    
    // Check if transition is in allowed list
    final allowed = _validTransitions[from] ?? [];
    return allowed.contains(to);
  }

  /// Coerce to error state with logging
  void _coerceToError(String reason) {
    _currentStatus.value = RecordingStatus.error;
    _hasError.value = true;
    _isVisible.value = true;
    
    logx('[PIPELINE][${_traceId.value}] coerced to error: $reason', tag: 'PIPELINE');
  }

  /// Reset to initial state
  void reset() {
    _currentStatus.value = RecordingStatus.local;
    _isVisible.value = false;
    _hasError.value = false;
    _traceId.value = '';
  }

  /// Get or create tagged PipelineRx for UI reactivity
  PipelineRx _rx(String recordingId) =>
    Get.put(PipelineRx(), tag: 'pipe_$recordingId', permanent: false);

  /// Bridge backend status to UI state - called from realtime/polling
  void onBackendStatus(String recordingId, RecordingStatus s) {
    // Keep existing validation/guards here, then update UI
    final rx = _rx(recordingId);
    
    switch (s) {
      case RecordingStatus.local:
        rx.setState(s, p: 0.0, key: 'idle', showProgress: true);
        break;
      case RecordingStatus.uploading:
        rx.setState(s, p: 0.15, key: 'upload', showProgress: true);
        break;
      case RecordingStatus.transcribing:
        rx.setState(s, p: 0.45, key: 'transcribe', showProgress: true);
        break;
      case RecordingStatus.summarizing:
        rx.setState(s, p: 0.75, key: 'summarize', showProgress: true);
        break;
      case RecordingStatus.ready:
        rx.setState(s, p: 1.0, key: 'done', showProgress: true);
        break;
      case RecordingStatus.error:
        rx.setState(s, p: 0.0, key: 'error', showProgress: false);
        break;
    }
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
