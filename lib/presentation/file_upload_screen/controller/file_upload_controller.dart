import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/file_upload_service.dart';

class FileUploadController extends GetxController {
  final FileUploadService _fileUploadService = FileUploadService.instance;

  // Observable states
  RxBool isUploading = false.obs;
  RxString uploadProgress = ''.obs;
  RxBool showErrorBanner = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('FileUploadController initialized');
  }

  /// Handle file selection and upload
  void onSelectFilePressed() async {
    if (isUploading.value) return;

    try {
      // Clear any previous errors
      dismissError();

      // Start upload process
      isUploading.value = true;
      uploadProgress.value = 'Preparing upload...';

      debugPrint('ðŸŽ¯ Starting file selection and upload');

      // Update progress
      uploadProgress.value = 'Selecting file...';

      // Use file upload service
      final result = await _fileUploadService.pickAndUploadAudioFile();

      if (result['success']) {
        // Success - navigate to summary with run_id
        uploadProgress.value = 'Upload complete!';

        debugPrint('âœ… Upload successful: ${result['run_id']}');

        // Small delay to show success message
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to Summary screen with run_id
        Get.toNamed(
          Routes.recordingSummaryScreen,
          arguments: {'run_id': result['run_id']},
        );
      } else {
        // Handle error
        final errorMsg =
            result['message'] ?? result['error'] ?? 'Upload failed';
        showError(errorMsg);
        debugPrint('âŒ Upload failed: $errorMsg');
      }
    } catch (e) {
      showError('Unexpected error during upload: $e');
      debugPrint('âŒ Upload controller error: $e');
    } finally {
      isUploading.value = false;
      uploadProgress.value = '';
    }
  }

  /// Show error banner with message
  void showError(String message) {
    errorMessage.value = message;
    showErrorBanner.value = true;

    // Auto-dismiss after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      dismissError();
    });
  }

  /// Dismiss error banner
  void dismissError() {
    showErrorBanner.value = false;
    errorMessage.value = '';
  }

  /// Handle back navigation
  void onBackPressed() {
    if (isUploading.value) {
      // Show confirmation dialog if upload is in progress
      Get.dialog(
        AlertDialog(
          title: Text('Cancel Upload?'),
          content: Text(
              'Your file upload is in progress. Are you sure you want to cancel?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Continue Upload'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(); // Go back to previous screen
              },
              child: Text('Cancel Upload'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    debugPrint('FileUploadController disposed');
    super.onClose();
  }
}
