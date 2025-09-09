import 'dart:async';


import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';
import '../../../services/recording_store.dart';
import '../models/recording_summary_model.dart';

class RecordingSummaryController extends GetxController {
  Rx<RecordingSummaryModel> recordingSummaryModelObj =
      RecordingSummaryModel().obs;

  // Recording store instance
  final RecordingStore _recordingStore = RecordingStore.instance;

  // Current recording data
  Rx<RecordingItem?> currentRecording = Rx<RecordingItem?>(null);

  String? recordingId;
  StreamSubscription<List<RecordingItem>>? _sub;

  @override
  void onInit() {
    super.onInit();

    // Read recording id from route params/args
    final id = Get.parameters['id'] ?? Get.arguments?['id'];

    // Require 'id' param validation
    if (id == null) {
      _navigateToLibraryWithError();
      return;
    }

    recordingId = id;
    currentRecording.value = _recordingStore.getById(id);

    // Subscribe to updates
    _sub = _recordingStore.stream.listen((_) {
      currentRecording.value = _recordingStore.getById(id);
    });
  }

  /// Navigate to Recording Library and show error toast
  void _navigateToLibraryWithError() {
    Get.offNamed('/recording_library_screen');
    Get.snackbar(
      'Error',
      'Recording not found.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: appTheme.red_400,
      colorText: appTheme.white_A700,
    );
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// Load recording data by ID
  void _loadRecordingData() {
    if (recordingId == null) return;

    final recording = _recordingStore.getById(recordingId!);
    if (recording != null) {
      currentRecording.value = recording;

      // Update the model with recording data
      recordingSummaryModelObj.update((model) {
        model?.summaryText?.value = recording.summaryText ?? '';
      });
    }
  }

  /// Update summary text with optimistic update
  Future<void> updateSummaryText(String newSummary) async {
    if (currentRecording.value == null) return;

    try {
      // Use RecordingStore.addOrUpdate with only available parameters (no Rx types)
      await _recordingStore.addOrUpdate(
        id: recordingId!,
        summaryText: newSummary,
      );

      // Update local state by fetching the updated recording from store
      currentRecording.value = _recordingStore.getById(recordingId!);
      recordingSummaryModelObj.value.summaryText?.value = newSummary;
    } catch (e) {
      // Error is already handled by RecordingStore (rollback occurred)
      Get.snackbar(
        'Error',
        'Failed to update summary. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  /// Update enriched recording data after AI processing
  Future<void> updateEnrichedRecording({
    String? transcriptText,
    String? summaryText,
    List<String>? actionsList,
    List<String>? keypointsList,
  }) async {
    if (recordingId == null) return;

    try {
      // Use RecordingStore.addOrUpdate with only available enrichment parameters
      await _recordingStore.addOrUpdate(
        id: recordingId!,
        transcript: transcriptText,
        summaryText: summaryText,
        actions: actionsList,
        keypoints: keypointsList,
      );

      // Update local state by fetching the updated recording from store
      currentRecording.value = _recordingStore.getById(recordingId!);
    } catch (e) {
      // Error is already handled by RecordingStore (rollback occurred)
      Get.snackbar(
        'Error',
        'Failed to update recording enrichment. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  @override
  void onClose() {
    // Cancel subscription if not null
    _sub?.cancel();
    super.onClose();
  }
}

extension ListObservable on List<String> {
  RxList<String> asObservable() {
    return RxList<String>.from(this);
  }
}
