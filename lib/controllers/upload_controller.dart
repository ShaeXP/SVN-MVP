import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lashae_s_application/services/recording_backend_service.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';
import 'package:lashae_s_application/services/connectivity_service.dart';
import 'package:lashae_s_application/services/permission_service.dart';
import 'pipeline_progress_controller.dart';

class UploadController extends GetxController {
  final isUploading = false.obs;
  final errorMessage = ''.obs;

  /// Pick a file and upload it through the pipeline
  Future<void> pickFileAndUpload() async {
    // Check offline state
    final connectivity = ConnectivityService.instance;
    if (connectivity.isOffline.value) {
      Get.snackbar(
        'Offline',
        'You\'re offline. We\'ll try again when you\'re back online.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      // Clear any previous error
      errorMessage.value = '';
      isUploading.value = true;

      // Check file access permission (if needed for platform)
      final permissionService = PermissionService.instance;
      final hasFilePermission = await permissionService.ensureFileAccessPermission();
      if (!hasFilePermission) {
        isUploading.value = false;
        Get.snackbar(
          'Permission Required',
          'We need access to your files to upload a recording.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // 1. File picker
      FilePickerResult? pickerResult;
      try {
        pickerResult = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );
      } catch (e) {
        isUploading.value = false;
        Get.snackbar(
          'File Selection Error',
          'That file couldn\'t be opened. Try a different one or check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      if (pickerResult == null || pickerResult.files.isEmpty) {
        isUploading.value = false;
        return; // User cancelled
      }

      final file = File(pickerResult.files.first.path!);
      if (!await file.exists()) {
        isUploading.value = false;
        Get.snackbar(
          'File Error',
          'That file couldn\'t be opened. Try a different one or check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 2. Get user ID
      final supabase = Supa.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Please sign in to upload files');
      }

      // 3. Insert recording row and upload file
      final uploadResult = await RecordingBackendService.instance.insertThenUpload(
        file: file,
        userId: user.id,
        uiTitle: pickerResult.files.first.name,
      );

      final recordingId = uploadResult['id'] as String;

      // 4. Attach progress overlay
      Get.find<PipelineProgressController>().attachToRecording(recordingId);
      Get.find<PipelineProgressController>().onStatusChange('uploading');

      // 5. Trigger pipeline
      await RecordingBackendService.instance.runSvPipeline(
        recordingId: recordingId,
        storagePath: uploadResult['storage_path'] as String,
      );

      // Overlay subscription will handle status updates from here
      isUploading.value = false;

    } catch (e) {
      isUploading.value = false;
      errorMessage.value = e.toString();
      Get.snackbar(
        'Upload Failed',
        'Could not upload file: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'm4a':
      case 'mp4':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'caf':
        return 'audio/x-caf';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      default:
        return 'audio/mpeg'; // Default fallback
    }
  }
}
