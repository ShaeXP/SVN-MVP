import 'package:lashae_s_application/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/routes/recording_details_args.dart';

import '../../../services/file_upload_service.dart';
import '../../../services/pipeline_tracker.dart';
import '../../../controllers/progress_controller.dart';
import '../../../controllers/recording_state_coordinator.dart';
import '../../../domain/recordings/recording_status.dart';
import '../../../domain/recordings/pipeline_view_state.dart';
import '../../../services/pipeline_realtime_helper.dart';
import '../../../services/realtime_helper.dart';
import '../../../debug/metrics_tracker.dart';

class FileUploadController extends GetxController {
  final FileUploadService _fileUploadService = FileUploadService.instance;

  // Observable states
  RxBool isUploading = false.obs;
  RxString uploadProgress = 'Ready to upload'.obs;
  RxBool showErrorBanner = false.obs;
  RxString errorMessage = ''.obs;
  
  // Upload progress properties
  RxDouble uploadProgressPercent = 0.0.obs;
  RxString uploadStage = 'local'.obs;
  String? get currentRecordingId => _currentRecordingId;
  String? _currentRecordingId;
  String? _currentRunId;

  @override
  void onInit() {
    super.onInit();
    debugPrint('FileUploadController initialized');
    
    // Listen for pipeline completion
    ever(PipelineTracker.I.status, (PipeStage stage) {
      if (stage == PipeStage.ready) {
        // Track pipeline completion metrics (debug only)
        if (kDebugMode) {
          final recordingId = PipelineTracker.I.recordingId.value;
          if (recordingId != null) {
            MetricsTracker.I.trackPipelineCompletion(recordingId);
          }
        }
        
        // Pipeline complete - navigate to summary
        final runId = PipelineTracker.I.recordingId.value;
        if (runId != null) {
          // Use Get.toNamed instead of Get.offAllNamed to avoid navigation conflicts
          Get.toNamed(
            Routes.recordingSummary,
            arguments: RecordingDetailsArgs(runId),
          );
        }
      } else if (stage == PipeStage.error) {
        // Pipeline failed - reset states
        isUploading.value = false;
        uploadProgress.value = 'Upload failed';
        uploadStage.value = 'error';
        uploadProgressPercent.value = 1.0;
      }
    });
    
    // Listen for pipeline progress updates
    ever(PipelineTracker.I.status, (PipeStage stage) {
      switch (stage) {
        case PipeStage.local:
          uploadStage.value = 'local';
          uploadProgressPercent.value = 0.0;
          break;
        case PipeStage.uploading:
          uploadStage.value = 'uploading';
          uploadProgressPercent.value = 0.25;
          break;
        case PipeStage.uploaded:
          uploadStage.value = 'uploaded';
          uploadProgressPercent.value = 0.3;
          break;
        case PipeStage.transcribing:
          uploadStage.value = 'transcribing';
          uploadProgressPercent.value = 0.65;
          break;
        case PipeStage.summarizing:
          uploadStage.value = 'summarizing';
          uploadProgressPercent.value = 0.95;
          break;
        case PipeStage.ready:
          uploadStage.value = 'ready';
          uploadProgressPercent.value = 1.0;
          break;
        case PipeStage.error:
          uploadStage.value = 'error';
          uploadProgressPercent.value = 1.0;
          break;
      }
    });
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
      print('DEBUG FILE UPLOAD CONTROLLER: isUploading set to ${isUploading.value}');

      debugPrint('ðŸŽ¯ Starting file selection and upload');

      // Update progress
      uploadProgress.value = 'Selecting file...';

      // Use file upload service
      final result = await _fileUploadService.pickAndUploadAudioFile();

      if (result['success']) {
        // Success - get recording ID
        _currentRecordingId = result['run_id'];
        _currentRunId = result['runId'] as String?;
        uploadProgress.value = 'Upload complete!';

        debugPrint('âœ… Upload successful: ${result['run_id']}, runId: $_currentRunId');

        // Create PipelineRx IMMEDIATELY and initialize
        final rx = Get.put(PipelineRx(), tag: 'pipe_$_currentRecordingId', permanent: false);
        rx.setState(RecordingStatus.local, p: 0.0, key: 'idle', showProgress: true);
        
        // If we have a runId, subscribe to pipeline_runs for real-time updates
        if (_currentRunId != null) {
          await PipelineRealtimeHelper.seedInitialState(_currentRunId!);
          PipelineRealtimeHelper.wireRunChannel(_currentRunId!);
          debugPrint('[SVN] Pipeline Realtime channel created for run=$_currentRunId');
        } else {
          // Fallback to old method if no runId
          await RealtimeHelper.seedInitialStatus(_currentRecordingId!);
          RealtimeHelper.wireRecordingChannel(_currentRecordingId!);
          debugPrint('[SVN] Fallback Realtime channel created for recording=$_currentRecordingId');
        }
        
        // THEN call coordinator
        final coordinator = Get.find<RecordingStateCoordinator>();
        coordinator.onBackendStatus(_currentRecordingId!, RecordingStatus.uploading);

        // Start progress tracking for real-time updates
        final progressController = Get.find<ProgressController>();
        progressController.start(result['run_id']);

        // Don't navigate immediately - let the progress controller handle navigation
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
      uploadProgress.value = 'Ready to upload';
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
              onPressed: () => Get.back(id: 1),
              child: Text('Continue Upload'),
            ),
            TextButton(
              onPressed: () {
                Get.back(id: 1); // Close dialog
                Get.back(id: 1); // Go back to previous screen
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
    // Clean up PipelineRx and realtime subscriptions
    if (_currentRunId != null) {
      PipelineRealtimeHelper.cleanupChannel(_currentRunId!);
    }
    if (_currentRecordingId != null) {
      RealtimeHelper.cleanupChannel(_currentRecordingId!);
      Get.delete<PipelineRx>(tag: 'pipe_$_currentRecordingId');
    }
    debugPrint('FileUploadController disposed');
    super.onClose();
  }
}
