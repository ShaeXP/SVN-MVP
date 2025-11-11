import 'package:get/get.dart';
import 'recording_status.dart';

/// Pipeline view state for UI reactivity and animations
/// Separate from domain logic - purely for UI state management
class PipelineRx extends GetxController {
  final status = RecordingStatus.local.obs;
  final progress = 0.0.obs;        // 0..1
  final hasProgress = false.obs;
  final animKey = 'idle'.obs;

  /// Update all UI state properties atomically
  void setState(RecordingStatus s, {double? p, String? key, bool? showProgress}) {
    status.value = s;
    if (p != null) progress.value = p.clamp(0.0, 1.0);
    if (key != null) animKey.value = key;
    if (showProgress != null) hasProgress.value = showProgress;
    update();
  }

  /// Reset to initial state
  void reset() {
    status.value = RecordingStatus.local;
    progress.value = 0.0;
    hasProgress.value = false;
    animKey.value = 'idle';
    update();
  }
}
