import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../debug/metrics_tracker.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/services/audio_recorder_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'pipeline_progress_controller.dart';
import 'recording_state_coordinator.dart';
import '../domain/recordings/recording_status.dart';
import '../domain/recordings/pipeline_view_state.dart';
import '../services/pipeline_realtime_helper.dart';
import '../services/realtime_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/haptics.dart';
import '../presentation/settings_screen/controller/settings_controller.dart';
import '../app/routes/app_routes.dart';
import '../app/navigation/bottom_nav_controller.dart';
import '../presentation/library/library_controller.dart';
import '../utils/summary_navigation.dart';
import '../models/summary_style_option.dart';
import '../services/pipeline_trigger_service.dart';
import '../utils/recording_permission_helper.dart';
import '../services/permission_service.dart';
import 'package:flutter/services.dart';

enum RecordState { idle, recording, paused, processing, error }

enum UploadStatus { idle, inProgress, success, error }

class RecordController extends GetxController {
  RecordController({required this.recorder, required this.pipeline});
  final AudioRecorderService recorder;
  final PipelineService pipeline;

  final recordState = RecordState.idle.obs;
  final errorMessage = ''.obs;
  final Rx<Duration> recordDuration = Duration.zero.obs;
  final RxDouble amplitude = 0.0.obs;
  final Rx<PipeStage> pipelineStage = PipeStage.local.obs;
  // Upload-specific status tracking
  final Rx<UploadStatus> uploadStatus = UploadStatus.idle.obs;
  String? _lastUploadRecordingId;
  Timer? _durationTimer;
  StreamSubscription<RecordingDisposition>? _ampSub;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  String? _currentRecordingId;
  String? _currentRunId;

  // Per-recording summary style - single source of truth
  final Rx<SummaryStyleOption> selectedSummaryStyle = SummaryStyles.quickRecapActionItems.obs;
  bool _styleInitializedThisVisit = false;
  
  // Backward compatibility: expose key as string for existing code
  String get summaryStyleForThisRecording => selectedSummaryStyle.value.key;

  bool get isRecording => recordState.value == RecordState.recording;
  String? get currentRecordingId => _currentRecordingId;

  bool _debounce() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 350) return false;
    _lastTap = now;
    return true;
  }

  /// Reset the per-recording style from global default (call when Record tab is shown)
  Future<void> resetStyleFromDefaultIfNeeded() async {
    if (_styleInitializedThisVisit) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final styleKey = prefs.getString('summarize_style') ?? 'quick_recap_action_items';
      selectedSummaryStyle.value = SummaryStyles.byKey(styleKey);
    } catch (_) {
      selectedSummaryStyle.value = SummaryStyles.quickRecapActionItems;
    }
    _styleInitializedThisVisit = true;
  }
  
  /// Handle summary style selection from UI
  void onSummaryStyleSelected(SummaryStyleOption option) {
    selectedSummaryStyle.value = option;
    debugPrint('[SUMMARY_STYLE] selected key=${option.key}');
  }

  /// Mark that a future visit should reinitialize from default
  void markNeedsStyleReset() {
    _styleInitializedThisVisit = false;
  }

  // Backward-compat: keep toggleRecording but route to the new main-button handler
  Future<void> toggleRecording() async {
    final state = recordState.value;
    if (state == RecordState.idle || state == RecordState.error) {
      await startRecording();
    } else if (state == RecordState.recording) {
      await pauseRecording();
    } else if (state == RecordState.paused) {
      await resumeRecording();
    }
  }

  /// Start recording: creates a new recording and begins writing audio.
  Future<void> startRecording() async {
    debugPrint('[REC_CTRL] startRecording, state=${recordState.value}');
    
    // STRICT GUARD: Only allow start when state is idle or error
    if (recordState.value != RecordState.idle && recordState.value != RecordState.error) {
      debugPrint('[REC_CTRL] startRecording ignored due to invalid state');
      return;
    }
    
    if (!_debounce()) {
      debugPrint('[REC_CTRL] startRecording ignored; debounce active');
      return;
    }

    errorMessage.value = '';
    
    try {
      try { await Haptics.mediumTap(); } catch (_) {}
      
      // Check and request permissions before starting
      final permissionService = PermissionService.instance;
      final hasPermission = await permissionService.hasMicrophonePermission();
      if (!hasPermission) {
        debugPrint('[REC_CTRL] Microphone permission not granted, requesting...');
        final granted = await permissionService.ensureMicrophonePermission();
        if (!granted) {
          debugPrint('[REC_CTRL] Microphone permission denied after request');
          errorMessage.value = 'Microphone permission is required to record.';
          recordState.value = RecordState.error;
          Get.snackbar('Permission Required', 'Please grant microphone permission to record.');
          return;
        }
        debugPrint('[REC_CTRL] Microphone permission granted after request');
      }
      
      // Now safe to start the recorder
      await recorder.start();
      if (recorder.isRecording) {
        recordState.value = RecordState.recording;
        _startDurationTimer();
        _listenAmplitude();
        debugPrint('[REC_CTRL] Recording started successfully');
      } else {
        debugPrint('[REC_CTRL] Recorder.start() returned but isRecording=false');
        errorMessage.value = 'Could not start microphone. Check permissions.';
        recordState.value = RecordState.error;
        Get.snackbar('Recording', 'Could not start microphone.');
      }
    } on PlatformException catch (e, st) {
      debugPrint('[REC_CTRL][ERR] PlatformException in startRecording: $e');
      debugPrint('[REC_CTRL][ERR] Stack: $st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Failed to start recording. Please try again.';
      Get.snackbar('Recording Error', 'Failed to start recording. Please try again.');
    } catch (e, st) {
      debugPrint('[REC_CTRL][ERR] Unexpected error in startRecording: $e');
      debugPrint('[REC_CTRL][ERR] Stack: $st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Failed to start recording. Please try again.';
      Get.snackbar('Recording Error', 'Failed to start recording. Please try again.');
    }
  }

  /// Pause recording: pauses the current recording without discarding audio.
  Future<void> pauseRecording() async {
    debugPrint('[RECORD_CTRL] pauseRecording, state=${recordState.value}');
    if (recordState.value != RecordState.recording) {
      return; // Only valid when recording
    }
    if (!_debounce()) return;

    try {
      try { await Haptics.lightTap(); } catch (_) {}
      await recorder.pause();
      recordState.value = RecordState.paused;
      // Freeze amplitude at current value (don't cancel subscription)
      // The amplitude listener already checks for recording state, so it won't update
    } catch (e, st) {
      debugPrint('[RECORD_CTRL] pauseRecording error: $e\n$st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Failed to pause recording: $e';
    }
  }

  /// Resume recording: continues the same recording file.
  Future<void> resumeRecording() async {
    debugPrint('[RECORD_CTRL] resumeRecording, state=${recordState.value}');
    if (recordState.value != RecordState.paused) {
      return; // Only valid when paused
    }
    if (!_debounce()) return;

    try {
      try { await Haptics.lightTap(); } catch (_) {}
      await recorder.resume();
      recordState.value = RecordState.recording;
      _startDurationTimer();
      // Amplitude subscription should continue automatically
    } catch (e, st) {
      debugPrint('[RECORD_CTRL] resumeRecording error: $e\n$st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Failed to resume recording: $e';
    }
  }

  /// Stop recording: finalizes the file and triggers the pipeline.
  Future<void> stopRecording() async {
    debugPrint('[REC_CTRL] stopRecording, state=${recordState.value}');
    
    // STRICT GUARD: Only allow stop when state is recording or paused
    if (recordState.value != RecordState.recording && recordState.value != RecordState.paused) {
      debugPrint('[REC_CTRL] stopRecording ignored due to invalid state');
      return;
    }
    
    if (!_debounce()) {
      debugPrint('[REC_CTRL] stopRecording ignored; debounce active');
      return;
    }

    try {
      try { await Haptics.lightTap(); } catch (_) {}
      
      // Set processing state before stopping (to prevent double-stops)
      recordState.value = RecordState.processing;
      
      // Stop the recorder and get the file path
      final path = await recorder.stop();
      
      debugPrint('[REC_CTRL] stopRecording got path=$path');
      
      if (path.isEmpty) {
        throw StateError('Recorder returned empty path');
      }
      
      // Cancel amplitude subscription and reset
      _cancelAmplitude();
      amplitude.value = 0.0;
      
      // Stop duration timer
      _stopDurationTimerAndReset();
      
      // Trigger pipeline
      await _runPipelineForCurrentRecording(path);
      
      // Show toast and navigate to Library
      _showRecordingSavedToast();
      _navigateToLibrary();
      
      // Pipeline will handle state transitions, but reset to idle after completion
      recordState.value = RecordState.idle;
    } on PlatformException catch (e, st) {
      debugPrint('[REC_CTRL][ERR] PlatformException in stopRecording: $e');
      debugPrint('[REC_CTRL][ERR] Stack: $st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Recording error. Please try again.';
      Get.snackbar('Recording Error', 'Recording error. Please try again.');
      _stopDurationTimerAndReset();
    } catch (e, st) {
      debugPrint('[REC_CTRL][ERR] Unexpected error in stopRecording: $e');
      debugPrint('[REC_CTRL][ERR] Stack: $st');
      recordState.value = RecordState.error;
      errorMessage.value = 'Recording error. Please try again.';
      Get.snackbar('Recording Error', 'Recording error. Please try again.');
      _stopDurationTimerAndReset();
    }
  }

  // Legacy methods for backward compatibility
  /// Main button handler: start/pause/resume only. Never triggers pipeline.
  Future<void> onMainButtonPressed() async {
    await toggleRecording();
  }

  /// Stop button handler: the only place that finalizes and runs the pipeline.
  Future<void> onStopButtonPressed() async {
    await stopRecording();
  }

  Future<void> _runPipelineForCurrentRecording(String path) async {
    debugPrint('[PIPELINE] runPipelineForRecording called, recordState=${recordState.value}');

    final f = File(path);
    if (!await f.exists() || await f.length() < 1024) {
      throw StateError('Audio too short or invalid.');
    }

    // Get style key from selectedSummaryStyle
    final styleKey = selectedSummaryStyle.value.key;
    debugPrint('[PIPELINE] start for live recording, styleKey=$styleKey');

    // Use the unified pipeline trigger service
    final triggerService = PipelineTriggerService.instance;
    
    // First, we need to get the recording ID and storage path from pipeline.run
    // But we want to use the unified trigger, so let's get the storage path first
    final result = await pipeline.run(path, summaryStyleOverride: styleKey);
    final recordingId = result['recordingId']!;
    final storagePath = result['storagePath'] as String? ?? result['storage_path'] as String?;
    
    if (storagePath == null) {
      throw StateError('Pipeline run did not return storage path');
    }
    
    // Now trigger the pipeline with the unified service
    await triggerService.runPipelineForRecording(
      recordingId: recordingId,
      storagePath: storagePath,
      summaryStyleKeyOverride: styleKey,
    );
    
    final runId = result['runId'];
    _currentRecordingId = recordingId;
    _currentRunId = runId;

    // Create PipelineRx IMMEDIATELY and initialize
    final rx = Get.put(PipelineRx(), tag: 'pipe_$recordingId', permanent: false);
    rx.setState(RecordingStatus.local, p: 0.0, key: 'idle', showProgress: true);

    // Realtime wiring
    if (runId != null) {
      await PipelineRealtimeHelper.seedInitialState(runId);
      PipelineRealtimeHelper.wireRunChannel(runId);
      debugPrint('[SVN] Pipeline Realtime channel created for run=$runId');
    } else {
      await RealtimeHelper.seedInitialStatus(recordingId);
      RealtimeHelper.wireRecordingChannel(recordingId);
      debugPrint('[SVN] Fallback Realtime channel created for recording=$recordingId');
    }

    // Notify coordinator
    final coordinator = Get.find<RecordingStateCoordinator>();
    coordinator.onBackendStatus(recordingId, RecordingStatus.uploading);

    // Start pipeline tracking for inline status indicator
    PipelineTracker.I.start(recordingId, openHud: false);
    _listenToPipelineStage();
    
    // Track pipeline start time for metrics (debug only)
    if (kDebugMode) {
      MetricsTracker.I.trackPipelineStart(recordingId);
    }
  }


  void _listenAmplitude() {
    try {
      // Cancel any existing subscription
      _ampSub?.cancel();
      
      final soundRecorder = recorder.recorder;
      if (soundRecorder == null) {
        debugPrint('[RECORD_CTRL] Recorder not available for amplitude');
        return;
      }

      // Set subscription duration for amplitude updates (60ms for responsive feel)
      soundRecorder.setSubscriptionDuration(const Duration(milliseconds: 60));

      // Subscribe to amplitude updates
      _ampSub = soundRecorder.onProgress?.listen((disposition) {
        // Only update amplitude when actively recording (not paused)
        if (recordState.value == RecordState.recording) {
          // Get raw dB value from recorder
          // Observed range: positive dB values ~0-70+ (NOT negative)
          // - Below ~20 dB: near-silence
          // - ~25-45 dB: normal speech
          // - ~45-65 dB: louder/close speech
          // - Above ~70 dB: very loud
          final rawDb = disposition.decibels ?? 0.0;
          
          // Define usable speech range based on observed logs
          const double minDb = 20.0;  // Below this = near-silence
          const double maxDb = 70.0;  // Above this = very loud
          
          // Linear normalize into 0..1
          double normalized = ((rawDb - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
          
          // Apply very mild curve (exponent > 1) to avoid clustering at 1.0
          // This keeps mid-range distinct from loud speech
          normalized = math.pow(normalized, 1.1).toDouble();
          
          // Light smoothing to reduce jitter (30% new value, 70% previous)
          // This prevents jumpiness while maintaining responsiveness
          const smoothing = 0.3;
          final previous = amplitude.value;
          final smoothed = previous * (1.0 - smoothing) + normalized * smoothing;
          
          // Clamp and store
          amplitude.value = smoothed.clamp(0.0, 1.0);
          
          // Log raw values occasionally for debugging (not every update)
          // Log every ~500ms to avoid spam
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now % 500 < 60) {
            final normLinear = ((rawDb - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
            debugPrint('[AMP_RAW] current=${rawDb.toStringAsFixed(1)}dB, normLinear=${normLinear.toStringAsFixed(3)}, normFinal=${amplitude.value.toStringAsFixed(3)}');
          }
        } else if (recordState.value == RecordState.paused) {
          // Freeze amplitude at a low value when paused
          if (amplitude.value > 0.0) {
            amplitude.value = amplitude.value * 0.3; // Reduce to 30% of current value
          }
        }
      }, onError: (error) {
        debugPrint('[RECORD_CTRL] Amplitude stream error: $error');
        amplitude.value = 0.0;
      });
    } catch (e) {
      debugPrint('[RECORD_CTRL] Error setting up amplitude: $e');
      amplitude.value = 0.0;
    }
  }

  void _cancelAmplitude() {
    _ampSub?.cancel();
    _ampSub = null;
  }

  /// Listen to pipeline tracker and update pipelineStage observable
  void _listenToPipelineStage() {
    final tracker = PipelineTracker.I;
    
    // Use ever() to listen to both recordingId and status changes
    // ever() automatically handles cleanup when controller is disposed
    ever(tracker.recordingId, (_) {
      _updatePipelineStage();
    });
    
    // Listen for pipeline completion (same as upload flow)
    ever(tracker.status, (PipeStage stage) {
      _updatePipelineStage();
      
      // Handle completion when pipeline becomes ready
      if (stage == PipeStage.ready) {
        final activeId = tracker.recordingId.value;
        if (activeId != null && activeId == _currentRecordingId) {
          // Live recording completion - handle navigation
          _handlePipelineCompleted(activeId);
        } else if (activeId != null) {
          // Upload completion - update upload status and store recording ID for CTA
          if (activeId != _currentRecordingId) {
            _lastUploadRecordingId = activeId;
            uploadStatus.value = UploadStatus.success;
            debugPrint('[RECORD_CTRL] Upload completed successfully: $activeId');
            // Reset pipelineStage to idle after a delay to allow UI to show completion
            Future.delayed(const Duration(milliseconds: 1500), () {
              final currentActiveId = tracker.recordingId.value;
              if (currentActiveId == activeId && activeId != _currentRecordingId) {
                pipelineStage.value = PipeStage.local;
                debugPrint('[RECORD_CTRL] Reset pipelineStage to idle for completed upload $activeId');
              }
            });
          }
        } else if (stage == PipeStage.error) {
          // Upload error - update upload status
          final activeId = tracker.recordingId.value;
          if (activeId != null && activeId != _currentRecordingId) {
            _lastUploadRecordingId = activeId;
            uploadStatus.value = UploadStatus.error;
            debugPrint('[RECORD_CTRL] Upload failed: $activeId');
          }
        }
      }
    });
    
    // Initial update
    _updatePipelineStage();
  }
  
  void _updatePipelineStage() {
    final tracker = PipelineTracker.I;
    final activeId = tracker.recordingId.value;
    final currentStage = tracker.status.value;
    
    // Update pipelineStage observable based on current tracking state
    if (activeId != null && currentStage != PipeStage.local) {
      pipelineStage.value = currentStage;
    } else {
      pipelineStage.value = PipeStage.local;
    }
  }
  
  /// Shared helper to get pipeline status label text
  String pipelineStatusLabel(PipeStage stage, {required bool isUpload}) {
    switch (stage) {
      case PipeStage.uploading:
        return isUpload ? 'Uploading your file...' : 'Uploading your note...';
      case PipeStage.uploaded:
      case PipeStage.transcribing:
        return 'Transcribing...';
      case PipeStage.summarizing:
        return 'Summarizing...';
      case PipeStage.ready:
        return 'Finalizing...';
      case PipeStage.error:
        return 'Something went wrong. Please try again.';
      default:
        return '';
    }
  }
  
  /// Show toast message after recording is saved
  void _showRecordingSavedToast() {
    Get.snackbar(
      'Note saved',
      'Processing in the background. Taking you to your Library…',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.white.withOpacity(0.9),
      colorText: Colors.black87,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// Navigate to Library tab
  void _navigateToLibrary() {
    try {
      final bottomNav = Get.find<BottomNavController>();
      bottomNav.goLibrary();
      
      // Mark recording as recently created for highlighting
      if (_currentRecordingId != null) {
        if (Get.isRegistered<LibraryController>()) {
          final libraryController = Get.find<LibraryController>();
          libraryController.markRecordingAsRecentlyCreated(_currentRecordingId!);
        }
      }
    } catch (e) {
      debugPrint('[RECORD_CTRL] Failed to navigate to Library: $e');
    }
  }
  
  /// Handle pipeline completion - same behavior as upload flow
  void _handlePipelineCompleted(String recordingId) {
    debugPrint('[RECORD_CTRL] Pipeline completed for recordingId=$recordingId');
    
    // Track pipeline completion metrics (debug only)
    if (kDebugMode) {
      MetricsTracker.I.trackPipelineCompletion(recordingId);
    }
    
    // Reset pipeline stage to idle
    pipelineStage.value = PipeStage.local;
    
    // Navigate to summary screen (same as upload flow)
    // Use the same navigation pattern as FileUploadController
    try {
      Get.toNamed(
        Routes.recordingSummary,
        arguments: {'recordingId': recordingId},
      );
    } catch (e) {
      debugPrint('[RECORD_CTRL] Failed to navigate to summary: $e');
    }
  }

  /// Handle file pick - immediately show activity in Upload tile
  void onFilePicked() {
    debugPrint('[RECORD_CTRL] File picked - setting upload status to inProgress');
    // Reset previous upload state
    _lastUploadRecordingId = null;
    uploadStatus.value = UploadStatus.inProgress;
    pipelineStage.value = PipeStage.uploading;
  }

  /// Handle upload tile CTA button press
  void onUploadTileCtaPressed() {
    if (_lastUploadRecordingId == null) {
      // Fallback: go to Library
      BottomNavController.I.goLibrary();
      return;
    }
    
    try {
      // Use standard navigation helper to open recording summary
      openRecordingSummary(recordingId: _lastUploadRecordingId!);
    } catch (e) {
      debugPrint('[RECORD_CTRL] Failed to navigate to summary: $e');
      // Fallback to Library
      BottomNavController.I.goLibrary();
    }
  }

  void _startDurationTimer() {
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (recordState.value == RecordState.recording) {
        recordDuration.value = recordDuration.value + const Duration(seconds: 1);
      }
    });
  }

  void _stopDurationTimerAndReset() {
    _durationTimer?.cancel();
    _durationTimer = null;
    recordDuration.value = Duration.zero;
  }

  @override
  void onInit() {
    super.onInit();
    _listenToPipelineStage();
  }

  @override
  void onClose() {
    // Clean up amplitude subscription
    _cancelAmplitude();
    // Clean up realtime subscriptions
    if (_currentRunId != null) {
      PipelineRealtimeHelper.cleanupChannel(_currentRunId!);
    }
    if (_currentRecordingId != null) {
      RealtimeHelper.cleanupChannel(_currentRecordingId!);
    }
    super.onClose();
  }

}