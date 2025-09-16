import 'dart:io';

import '../../../core/app_export.dart';

class RecordingSuccessController extends GetxController {
  RxInt selectedBottomNavIndex = 0.obs;
  RxBool isProcessing = false.obs;
  RxString processingStatus = 'Recording successfully saved.'.obs;
  String? transcriptId;
  File? audioFile;

  @override
  void onInit() {
    super.onInit();
    // Get transcript_id from arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    transcriptId = arguments?['transcript_id'];
    audioFile = arguments?['audioFile'] as File?;
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// btn_goToSummary → Recording Summary Screen with transcript_id
  void onGoToSummaryPressed() async {
    if (isProcessing.value) return;

    // Ensure we have a transcript_id
    if (transcriptId == null) {
      Get.snackbar(
        'Error',
        'Transcript ID not found',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      Get.toNamed(AppRoutes.recordingLibraryScreen);
      return;
    }

    // Navigate to Recording Summary Screen with transcript_id
    Get.toNamed(
      AppRoutes.recordingSummaryScreen,
      arguments: {'transcript_id': transcriptId},
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
