import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [RecordingControlScreen] screen with GetX.

class RecordingControlModel {
  // Observable variables for reactive state management
  Rx<String>? recordingTime = '00:05:32'.obs;
  Rx<String>? mainContentText = 'Your main app content would go here.'.obs;
  Rx<String>? demoText = 'Tap to open Bottom Sheet (for demo)'.obs;
  Rx<String>? stopRecordingTitle = 'Stop recording?'.obs;
  Rx<String>? stopRecordingSubtitle =
      'Choose an option to manage your recording.'.obs;
  Rx<String>? saveButtonText = 'Save'.obs;
  Rx<String>? redoButtonText = 'Redo'.obs;
  Rx<String>? cancelButtonText = 'Cancel'.obs;

  // Simple constructor with no parameters
  RecordingControlModel();
}
