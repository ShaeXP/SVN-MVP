import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../services/pipeline_tracker.dart';
import '../../services/authoritative_upload_service.dart';
import '../../services/pipeline_service.dart';
import '../../services/logger.dart';
import 'package:flutter/material.dart';

/// Upload panel UI state machine
enum UploadPanelState {
  idle,        // default "ready to upload / no error" UI
  uploading,   // file selected & being uploaded
  processing,  // pipeline running (transcribe/summarize)
  error,       // failure -> show error card
}

/// Controller for the Recording screen
/// Manages recording state, error handling, and retry/reset functionality
class RecordingScreenController extends GetxController {
  // Last upload information for retry
  String? _lastRecordingId;
  String? _lastLocalFilePath;
  String? _lastStoragePath;
  
  // Upload panel state machine
  final uploadPanelState = UploadPanelState.idle.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Check initial state - if tracker is in error but we're just initializing,
    // we may want to keep the error state for retry, but allow reset
    final currentStage = PipelineTracker.I.status.value;
    final activeId = PipelineTracker.I.recordingId.value;
    
    if (currentStage == PipeStage.error && activeId != null) {
      uploadPanelState.value = UploadPanelState.error;
      errorMessage.value = PipelineTracker.I.message.value.isNotEmpty
          ? PipelineTracker.I.message.value
          : 'Something went wrong';
      _lastRecordingId = activeId;
    } else if (activeId != null && currentStage != PipeStage.local && currentStage != PipeStage.ready) {
      // Active processing
      uploadPanelState.value = UploadPanelState.processing;
    } else {
      // Idle state
      uploadPanelState.value = UploadPanelState.idle;
    }
    
    // Listen to pipeline tracker for state changes
    ever(PipelineTracker.I.status, (PipeStage stage) {
      final activeId = PipelineTracker.I.recordingId.value;
      
      if (stage == PipeStage.error && activeId != null) {
        uploadPanelState.value = UploadPanelState.error;
        errorMessage.value = PipelineTracker.I.message.value.isNotEmpty
            ? PipelineTracker.I.message.value
            : 'Something went wrong';
        // Store the current recording ID for retry
        _lastRecordingId = activeId;
      } else if (stage == PipeStage.ready) {
        // Success - keep as processing until user explicitly resets or navigates away
        uploadPanelState.value = UploadPanelState.processing;
        errorMessage.value = '';
      } else if (activeId != null && stage != PipeStage.local && stage != PipeStage.ready) {
        // Active processing (uploading, transcribing, summarizing)
        uploadPanelState.value = UploadPanelState.processing;
      } else if (activeId == null && stage == PipeStage.local) {
        // No active recording - only go to idle if we're not in error state
        // (error state should persist until user resets)
        if (uploadPanelState.value != UploadPanelState.error) {
          uploadPanelState.value = UploadPanelState.idle;
          errorMessage.value = '';
        }
      }
    });
  }

  /// Store upload information for potential retry
  void storeUploadInfo({
    String? recordingId,
    String? localFilePath,
    String? storagePath,
  }) {
    if (recordingId != null) _lastRecordingId = recordingId;
    if (localFilePath != null) _lastLocalFilePath = localFilePath;
    if (storagePath != null) _lastStoragePath = storagePath;
    debugPrint('[RecordingScreenController] Stored upload info: recordingId=$recordingId, localPath=$localFilePath, storagePath=$storagePath');
    
    // Update state when upload starts
    if (recordingId != null || localFilePath != null) {
      uploadPanelState.value = UploadPanelState.uploading;
    }
  }

  /// Retry the last failed upload/recording
  Future<void> retryLastUpload() async {
    try {
      debugPrint('[RecordingScreenController] Retrying last upload...');
      
      // Set state to processing before retry
      uploadPanelState.value = UploadPanelState.processing;
      errorMessage.value = '';
      
      // If we have a recording ID, retry using that
      if (_lastRecordingId != null && _lastRecordingId!.isNotEmpty) {
        debugPrint('[RecordingScreenController] Retrying by recording ID: $_lastRecordingId');
        
        // Use PipelineService to rerun by recording ID
        final pipelineService = PipelineService();
        await pipelineService.rerunByRecordingId(_lastRecordingId!);
        
        // Restart tracking
        PipelineTracker.I.start(_lastRecordingId!);
        
        logx('[RecordingScreenController] Retry started for recording $_lastRecordingId', tag: 'RECORD');
        return;
      }
      
      // If we have a local file path, re-upload it
      if (_lastLocalFilePath != null && _lastLocalFilePath!.isNotEmpty) {
        final file = File(_lastLocalFilePath!);
        if (await file.exists()) {
          debugPrint('[RecordingScreenController] Retrying by re-uploading local file: $_lastLocalFilePath');
          
          final uploadService = AuthoritativeUploadService();
          final result = await uploadService.startPipelineFromLocalFile(
            localFilePath: _lastLocalFilePath!,
            sourceType: 'record',
          );
          
          if (result['success'] == true) {
            final recordingId = result['recording_id'] as String?;
            if (recordingId != null) {
              // Store the new recording ID
              _lastRecordingId = recordingId;
              PipelineTracker.I.start(recordingId);
            }
            logx('[RecordingScreenController] Retry upload started successfully', tag: 'RECORD');
          } else {
            throw Exception(result['message'] ?? result['error'] ?? 'Retry failed');
          }
          return;
        }
      }
      
      // No retry information available
      uploadPanelState.value = UploadPanelState.error;
      Get.snackbar(
        'Cannot Retry',
        'This upload can\'t be retried. Please try uploading again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[RecordingScreenController] Retry error: $e');
      // Log detailed exception for debugging
      logx('[RecordingScreenController] Retry exception: $e', tag: 'RECORD', error: e);
      
      // Set error state
      uploadPanelState.value = UploadPanelState.error;
      errorMessage.value = 'We couldn\'t retry that upload.';
      
      // Show user-friendly message instead of raw exception
      Get.snackbar(
        'Retry Failed',
        'Retry failed. Try starting a new upload instead.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Reset the Record UI to its default state (no error)
  void resetRecordUiState() {
    debugPrint('[RecordingScreenController] Resetting UI state');
    
    // Reset upload UI state back to default
    uploadPanelState.value = UploadPanelState.idle;
    
    // Clear error message
    errorMessage.value = '';
    
    // Clear last upload context
    _lastRecordingId = null;
    _lastLocalFilePath = null;
    _lastStoragePath = null;
    
    // Stop pipeline tracking (clears the error card)
    PipelineTracker.I.stop();
    
    logx('[RecordingScreenController] UI state reset to idle', tag: 'RECORD');
  }
}

