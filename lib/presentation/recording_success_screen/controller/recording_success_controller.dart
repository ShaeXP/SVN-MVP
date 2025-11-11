import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../app/routes/recording_details_args.dart';

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

  /// btn_goToSummary â†’ Recording Summary Screen with transcript_id
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
      Get.toNamed(Routes.recordingLibrary, id: 1);
      return;
    }

    // Navigate to Recording Summary Screen with transcript_id
    Get.toNamed(
      Routes.recordingSummary,
      id: 1,
      arguments: RecordingDetailsArgs(transcriptId!),
    );
  }

  void onBottomNavigationChanged(int index) {
    selectedBottomNavIndex.value = index;

    switch (index) {
      case 0:
        // Record tab
        Get.toNamed(Routes.home, id: 1);
        break;
      case 1:
        // Library tab
        Get.toNamed(Routes.recordingLibrary, id: 1);
        break;
      case 2:
        // Account tab
        Get.toNamed(Routes.settings, id: 1);
        break;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
