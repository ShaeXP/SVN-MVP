import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:get/get.dart';
import '../../../core/app_export.dart';
import '../models/recording_ready_model.dart';

class RecordingReadyController extends GetxController {
  Rx<RecordingReadyModel> recordingReadyModel = RecordingReadyModel().obs;
  RxInt selectedIndex = 0.obs;
  RxString timerDisplay = '00:00:00'.obs;
  RxString statusText = 'Ready to Record'.obs;
  RxBool isRecording = false.obs;

  @override
  void onInit() {
    super.onInit();
    recordingReadyModel.value = RecordingReadyModel();
  }

  void onPlayPausePressed() {
    if (isRecording.value) {
      pauseRecording();
    } else {
      startRecording();
    }
  }

  void startRecording() {
    isRecording.value = true;
    statusText.value = 'Recording...';
    Get.toNamed(Routes.activeRecordingScreen);
  }

  void pauseRecording() {
    isRecording.value = false;
    statusText.value = 'Paused';
    Get.toNamed(Routes.recordingPausedScreen);
  }

  void onStopPressed() {
    isRecording.value = false;
    statusText.value = 'Ready to Record';
    timerDisplay.value = '00:00:00';
  }

  @override
  void onClose() {
    super.onClose();
  }
}
