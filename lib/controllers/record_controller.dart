import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/services/audio_recorder_service.dart';
import 'pipeline_progress_controller.dart';
import 'recording_state_coordinator.dart';
import '../domain/recordings/recording_status.dart';
import '../domain/recordings/pipeline_view_state.dart';
import '../services/pipeline_realtime_helper.dart';
import '../services/realtime_helper.dart';

enum RecordState { idle, recording, processing }

class RecordController extends GetxController {
  RecordController({required this.recorder, required this.pipeline});
  final AudioRecorderService recorder;
  final PipelineService pipeline;

  final recordState = RecordState.idle.obs;
  final errorMessage = ''.obs;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  String? _currentRecordingId;
  String? _currentRunId;

  bool _debounce() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 350) return false;
    _lastTap = now;
    return true;
  }

  Future<void> toggleRecording() async {
    if (!_debounce()) return;

    try {
      // Clear any previous error
      errorMessage.value = '';

      if (recordState.value == RecordState.idle) {
        await recorder.start();
        if (recorder.isRecording) {
          recordState.value = RecordState.recording;
        } else {
          errorMessage.value = 'Could not start microphone. Check permissions.';
          Get.snackbar('Recording', 'Could not start microphone.');
        }
        return;
      }

      if (recordState.value == RecordState.recording) {
        recordState.value = RecordState.processing;
        final path = await recorder.stop();
        debugPrint('[SVN] recorded file: $path');
        final f = File(path);
        if (!await f.exists() || await f.length() < 1024) {
          recordState.value = RecordState.idle;
          errorMessage.value = 'Audio too short or invalid. Please try again.';
          Get.snackbar('Recording', 'Audio too short/invalid — try again.');
          return;
        }
        final result = await pipeline.run(path);
        final recordingId = result['recordingId']!;
        final runId = result['runId'];
        _currentRecordingId = recordingId;
        _currentRunId = runId;

        // Create PipelineRx IMMEDIATELY and initialize
        final rx = Get.put(PipelineRx(), tag: 'pipe_$recordingId', permanent: false);
        rx.setState(RecordingStatus.local, p: 0.0, key: 'idle', showProgress: true);
        
        // If we have a runId, subscribe to pipeline_runs for real-time updates
        if (runId != null) {
          await PipelineRealtimeHelper.seedInitialState(runId);
          PipelineRealtimeHelper.wireRunChannel(runId);
          debugPrint('[SVN] Pipeline Realtime channel created for run=$runId');
        } else {
          // Fallback to old method if no runId
          await RealtimeHelper.seedInitialStatus(recordingId);
          RealtimeHelper.wireRecordingChannel(recordingId);
          debugPrint('[SVN] Fallback Realtime channel created for recording=$recordingId');
        }
        
        // THEN call coordinator
        final coordinator = Get.find<RecordingStateCoordinator>();
        coordinator.onBackendStatus(recordingId, RecordingStatus.uploading);

        // Attach progress overlay (legacy)
        Get.find<PipelineProgressController>().attachToRecording(recordingId);
        Get.find<PipelineProgressController>().onStatusChange('uploading');

        // Don't navigate immediately - let overlay handle it when ready
        recordState.value = RecordState.idle;
      }
    } catch (e, st) {
      debugPrint('[SVN] toggleRecording error: $e\n$st');
      recordState.value = RecordState.idle;
      errorMessage.value = 'Recording failed. Please try again.';
      Get.snackbar('Processing', 'Processing failed — try again.');
    }
  }

  @override
  void onClose() {
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