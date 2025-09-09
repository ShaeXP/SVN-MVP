import 'dart:io';

import '../../../core/app_export.dart';

class RecordingSuccessController extends GetxController {
  RxInt selectedBottomNavIndex = 0.obs;
  RxBool isProcessing = false.obs;
  RxString processingStatus = 'Initializing...'.obs;
  String? currentRecordingId;
  File? audioFile;

  @override
  void onInit() {
    super.onInit();
    // Get recordingId from arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    currentRecordingId = arguments?['recordingId'];
    audioFile = arguments?['audioFile'] as File?;
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// btn_goToSummary → Recording Summary Actions with recordingId
  void onGoToSummaryPressed() async {
    if (isProcessing.value) return;

    // Ensure we have a recordingId
    if (currentRecordingId == null) {
      Get.snackbar(
        'Error',
        'Recording ID not found',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      Get.toNamed(AppRoutes.recordingLibraryScreen);
      return;
    }

    // Navigate to Recording Summary Actions with recordingId
    Get.toNamed(
      AppRoutes.recordingSummaryScreen,
      arguments: {'recordingId': currentRecordingId},
    );
  }

  void onBottomNavigationChanged(int index) {
    selectedBottomNavIndex.value = index;

    switch (index) {
      case 0:
        // Record tab
        Get.toNamed(AppRoutes.homeScreen);
        break;
      case 1:
        // Library tab
        Get.toNamed(AppRoutes.recordingLibraryScreen);
        break;
      case 2:
        // Account tab
        Get.toNamed(AppRoutes.settingsScreen);
        break;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}