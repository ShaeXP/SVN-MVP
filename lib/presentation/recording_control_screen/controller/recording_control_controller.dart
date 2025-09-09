import '../../../core/app_export.dart';
import '../../../services/recording_store.dart';
import '../models/recording_control_model.dart';

class RecordingControlController extends GetxController {
  Rx<RecordingControlModel> recordingControlModelObj =
      RecordingControlModel().obs;

  // Recording store instance
  final RecordingStore _recordingStore = Get.find<RecordingStore>();

  // Current recording ID
  String? currentRecordingId;

  @override
  void onInit() {
    super.onInit();
    // Get recordingId from arguments or RecordingStore
    final arguments = Get.arguments as Map<String, dynamic>?;
    currentRecordingId = arguments?['recordingId'] ?? _recordingStore.currentId;
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// btn_save → Finalize recording with optimistic updates and rollback
  void onSavePressed() async {
    if (currentRecordingId == null) {
      Get.snackbar(
        'Error',
        'No recording ID available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return;
    }

    try {
      // Create recording with current recordingId
      final now = DateTime.now();
      final hours =
          now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
      final amPm = now.hour >= 12 ? 'PM' : 'AM';
      final formattedDate =
          "${now.month}/${now.day}/${now.year} ${hours}:${now.minute.toString().padLeft(2, '0')} $amPm";

      final computedTitle =
          "Recording ${now.toIso8601String().substring(0, 16).replaceAll('T', ' ')}";
      final measuredDuration =
          "3:45"; // Mock duration - would come from actual recording

      // Use RecordingStore.addOrUpdate with only available parameters (no Rx types)
      await _recordingStore.addOrUpdate(
        id: currentRecordingId!,
        title: computedTitle,
        date: formattedDate,
        duration: measuredDuration,
      );

      // Clear current recording ID from store
      _recordingStore.clearCurrentId();

      // Show success message
      Get.snackbar(
        'Success',
        'Recording saved successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.green_600,
        colorText: appTheme.white_A700,
      );

      // Navigate to Recording Success Confirmation with recordingId
      Get.toNamed(
        AppRoutes.recordingSuccessScreen,
        arguments: {'recordingId': currentRecordingId},
      );
    } catch (e) {
      // Error is already handled by RecordingStore (rollback occurred)
      Get.snackbar(
        'Error',
        'Failed to save recording. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  /// btn_redo → Active Recording Screen with same recordingId
  void onRedoPressed() {
    // Navigate back to Active Recording Screen with same recordingId
    Get.toNamed(
      AppRoutes.activeRecordingScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  /// btn_cancel → Active Recording Screen with same recordingId
  void onCancelPressed() {
    // Navigate back to Active Recording Screen with same recordingId
    Get.toNamed(
      AppRoutes.activeRecordingScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}