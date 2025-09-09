import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [RecordingPausedScreen] screen with GetX.

class RecordingPausedModel {
  // Observable variables for reactive state management
  Rx<String> recordingTime = '00:03:45'.obs;
  Rx<bool> isRecording = false.obs;
  Rx<bool> isPaused = true.obs;
  Rx<String> recordingStatus = 'Paused Recording'.obs;

  // Simple constructor with no parameters
  RecordingPausedModel();
}
