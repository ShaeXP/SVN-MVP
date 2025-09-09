import '../../../core/app_export.dart';
import '../../../services/recording_store.dart';
import '../models/recording_paused_model.dart';

class RecordingPausedController extends GetxController {
  Rx<RecordingPausedModel> recordingPausedModelObj = RecordingPausedModel().obs;

  // Current recording ID
  String? currentRecordingId;

  @override
  void onInit() {
    super.onInit();
    // Get recordingId from arguments or RecordingStore
    final arguments = Get.arguments as Map<String, dynamic>?;
    currentRecordingId =
        arguments?['recordingId'] ?? RecordingStore.instance.currentId;
  }

  @override
  void onReady() {
    super.onReady();
  }

  // btn_resume → Active Recording Screen with same recordingId
  void onResumePressed() {
    // Navigate back to Active Recording Screen with same recordingId
    Get.toNamed(
      AppRoutes.activeRecordingScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  // btn_stop → Recording Control Screen with recordingId
  void onStopPressed() {
    // Navigate to Recording Control Screen with recordingId
    Get.toNamed(
      AppRoutes.recordingControlScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}