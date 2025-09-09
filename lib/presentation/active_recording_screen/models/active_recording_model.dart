import '../../../core/app_export.dart';

/// This class is used in the [ActiveRecordingScreen] screen with GetX.

class ActiveRecordingModel {
  // Recording state variables
  Rx<String> recordingTime = '00:03:45'.obs;
  Rx<bool> isRecording = true.obs;
  Rx<bool> isPaused = false.obs;
  Rx<String> recordingStatus = 'Active Recording'.obs;
  Rx<String> waveformImagePath = ImageConstant.imgGroupBlue200110x270.obs;

  // Control button states
  Rx<String> pauseButtonIcon = ImageConstant.imgPause.obs;
  Rx<String> stopButtonIcon = ImageConstant.imgSquare.obs;

  // Header images
  Rx<String> leftHeaderIcon = ImageConstant.imgGroup.obs;
  Rx<String> rightHeaderIcon = ImageConstant.imgGroupGray900.obs;

  // Simple constructor with no parameters
  ActiveRecordingModel();
}
