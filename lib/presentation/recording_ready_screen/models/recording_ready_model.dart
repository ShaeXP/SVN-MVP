import 'package:get/get.dart';
import '../../../core/app_export.dart';

class RecordingReadyModel {
  Rx<String>? timerDisplay;
  Rx<String>? statusText;
  Rx<bool>? isRecording;
  Rx<bool>? isPlaying;

  RecordingReadyModel({
    this.timerDisplay,
    this.statusText,
    this.isRecording,
    this.isPlaying,
  }) {
    timerDisplay = timerDisplay ?? '00:00:00'.obs;
    statusText = statusText ?? 'Ready to Record'.obs;
    isRecording = isRecording ?? false.obs;
    isPlaying = isPlaying ?? false.obs;
  }
}
