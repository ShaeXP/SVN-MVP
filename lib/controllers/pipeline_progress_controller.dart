import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/routes/app_routes.dart';
import '../ui/widgets/success_toast_lottie.dart';
import '../services/supabase_service.dart';

class PipelineProgressController extends GetxController {
  // Observable state
  final isVisible = false.obs;
  final stage = 'Uploading'.obs;
  final percent = Rxn<double>();
  final errorCode = Rxn<String>();
  final recordingId = Rxn<String>();

  // Private state
  RealtimeChannel? _subscription;
  String? _cachedRecordingId;

  @override
  void onInit() {
    super.onInit();
    // Re-attach on app resume if we have a cached recording
    _checkForReattach();
  }

  @override
  void onClose() {
    detach();
    super.onClose();
  }

  /// Attach to a recording and start monitoring its status
  void attachToRecording(String id) {
    // Stop any existing subscription
    detach();
    
    recordingId.value = id;
    _cachedRecordingId = id;
    isVisible.value = true;
    stage.value = 'Uploading';
    percent.value = null;
    errorCode.value = null;

    // Start Supabase realtime subscription
    _startSubscription(id);
  }

  /// Detach from current recording and hide overlay
  void detach() {
    _subscription?.unsubscribe();
    _subscription = null;
    
    isVisible.value = false;
    recordingId.value = null;
    _cachedRecordingId = null;
    stage.value = 'Uploading';
    percent.value = null;
    errorCode.value = null;
  }

  /// Handle status changes from the pipeline
  void onStatusChange(String status) {
    switch (status.toLowerCase()) {
      case 'local':
      case 'uploading':
        stage.value = 'Uploading';
        percent.value = 0.0; // Start with 0% for upload
        break;
      case 'uploaded':
        stage.value = 'Transcribing';
        percent.value = 25.0; // Upload complete, start transcribing
        break;
      case 'transcribing':
        stage.value = 'Transcribing';
        percent.value = 50.0; // Transcribing in progress
        break;
      case 'summarizing':
        stage.value = 'Summarizing';
        percent.value = 75.0; // Summarizing in progress
        break;
      case 'ready':
        stage.value = 'Finalizing';
        percent.value = 100.0; // Complete
        // Small delay before showing success
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleReady();
        });
        break;
      case 'error':
        _handleError();
        break;
      default:
        // Unknown status, show as processing
        stage.value = 'Processing';
        percent.value = null;
        break;
    }
  }

  /// Set upload progress percentage
  void setUploadProgress(double pct) {
    if (stage.value == 'Uploading') {
      percent.value = pct;
    }
  }

  /// Start Supabase realtime subscription for recording status
  void _startSubscription(String id) {
    final supabase = SupabaseService.instance.client;
    
    _subscription = supabase
        .channel('recording_$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'recordings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: id,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            if (status != null) {
              onStatusChange(status);
            }
          },
        )
        .subscribe();
  }

  /// Handle ready status - navigate to summary
  void _handleReady() {
    final id = recordingId.value;
    if (id == null) return;

    // Show success toast
    if (Get.context != null) {
      showSuccessToastLottie(Get.context!);
    }

    // Navigate to summary if not already there
    if (Get.currentRoute != Routes.recordingSummaryScreen) {
      Get.toNamed(Routes.recordingSummaryScreen, arguments: {'recordingId': id});
    }
    
    // Detach after navigation
    detach();
  }

  /// Handle error status - show toast and detach
  void _handleError() {
    final code = errorCode.value;
    final message = code != null 
        ? "We couldn't finish processing this note. Nothing was published. Code: $code"
        : "We couldn't finish processing this note. Nothing was published.";
    
    Get.snackbar(
      'Processing Failed',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
    );
    
    detach();
  }

  /// Check if we need to re-attach on app resume
  void _checkForReattach() {
    if (_cachedRecordingId != null && isVisible.value == false) {
      // Re-attach if we have a cached recording and overlay is not visible
      attachToRecording(_cachedRecordingId!);
    }
  }

  /// Set error code for debugging
  void setErrorCode(String code) {
    errorCode.value = code;
  }
}
