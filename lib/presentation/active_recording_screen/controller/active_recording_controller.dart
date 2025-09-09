import 'dart:async';

import '../../../core/app_export.dart';
import '../../../services/recording_store.dart';
import '../models/active_recording_model.dart';

class ActiveRecordingController extends GetxController {
  Rx<ActiveRecordingModel> activeRecordingModelObj = ActiveRecordingModel().obs;

  Timer? recordingTimer;
  RxInt totalSeconds = 225.obs; // Starting with 00:03:45 (3 minutes 45 seconds)
  RxString recordingTime = '00:03:45'.obs;
  RxBool isRecording = true.obs;
  RxBool isPaused = false.obs;

  // Current recording ID
  String? currentRecordingId;

  @override
  void onInit() {
    super.onInit();
    // Get recordingId from arguments or RecordingStore
    final arguments = Get.arguments as Map<String, dynamic>?;
    currentRecordingId =
        arguments?['recordingId'] ?? RecordingStore.instance.currentId;

    // Ensure we have a recordingId
    if (currentRecordingId == null) {
      currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
      RecordingStore.instance.setCurrentId(currentRecordingId!);
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  void startRecordingTimer() {
    recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isRecording.value && !isPaused.value) {
        totalSeconds.value++;
        updateRecordingTimeDisplay();
      }
    });
  }

  void updateRecordingTimeDisplay() {
    int hours = totalSeconds.value ~/ 3600;
    int minutes = (totalSeconds.value % 3600) ~/ 60;
    int seconds = totalSeconds.value % 60;

    recordingTime.value = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void pauseRecording() {
    isPaused.value = true;
    isRecording.value = false;
    // Navigate to Recording Paused Screen with recordingId
    Get.toNamed(
      AppRoutes.recordingPausedScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  void stopRecording() {
    recordingTimer?.cancel();
    isRecording.value = false;
    isPaused.value = false;
    // Navigate to Recording Control Screen with recordingId
    Get.toNamed(
      AppRoutes.recordingControlScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  void resumeRecording() {
    isPaused.value = false;
    isRecording.value = true;
  }

  // btn_pause → Recording Paused Screen with recordingId
  void onPausePressed() {
    pauseRecording();
  }

  // btn_stop → Recording Control Screen with recordingId
  void onStopPressed() {
    stopRecording();
  }

  @override
  void onClose() {
    super.onClose();
  }
}