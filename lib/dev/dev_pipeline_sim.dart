import 'dart:async';
import '../domain/recordings/recording_status.dart';
import '../domain/recordings/pipeline_view_state.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// Debug pipeline simulator for testing animations
/// Only available in debug mode
Future<void> devSimulatePipeline(String recordingId) async {
  if (!kDebugMode) return;
  
  try {
    final rx = Get.find<PipelineRx>(tag: 'pipe_$recordingId');
    final seq = [
      RecordingStatus.uploading,
      RecordingStatus.transcribing,
      RecordingStatus.summarizing,
      RecordingStatus.ready,
    ];
    
    for (final s in seq) {
      // Directly set UI state; coordinator paths are tested elsewhere
      switch (s) {
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
        default: 
          break;
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }
  } catch (e) {
    debugPrint('Debug simulator error: $e');
  }
}
