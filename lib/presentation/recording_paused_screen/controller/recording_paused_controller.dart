import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:get/get.dart';
import '../../../core/app_export.dart';
import '../../../services/recording_store.dart';
import '../models/recording_paused_model.dart';

class RecordingPausedController extends GetxController {
  Rx<RecordingPausedModel> recordingPausedModelObj = RecordingPausedModel().obs;

  // Current recording ID and local path
  String? currentRecordingId;
  String? localPath;

  @override
  void onInit() {
    super.onInit();
    // Get recordingId and localPath from arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    currentRecordingId =
        arguments?['recordingId'] ?? RecordingStore.instance.currentId;
    localPath = arguments?['localPath'] as String?;
  }

  @override
  void onReady() {
    super.onReady();
  }

  // btn_resume â†’ Active Recording Screen with same recordingId
  void onResumePressed() {
    // Navigate back to Active Recording Screen with same recordingId
    Get.toNamed(
      Routes.activeRecording,
      id: 1, // Use navigator id: 1 for Record tab's nested navigator
      arguments: {'recordingId': currentRecordingId},
    );
  }

  // btn_stop → Recording Ready Screen with localPath if available
  void onStopPressed() {
    // Navigate to Recording Ready Screen with localPath if available
    Get.toNamed(
      Routes.recordingReady,
      id: 1, // Use navigator id: 1 for Record tab's nested navigator
      arguments: {
        'localPath': localPath,
        'recordingId': currentRecordingId,
      },
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
