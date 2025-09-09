import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';
import '../../../services/recording_store.dart';
import '../models/recording_library_model.dart';

class RecordingLibraryController extends GetxController {
  late TextEditingController searchController;
  Rx<RecordingLibraryModel> recordingLibraryModelObj =
      RecordingLibraryModel().obs;

  // Stream subscription
  StreamSubscription<List<RecordingItem>>? _recordingSubscription;

  // Recording store instance
  final RecordingStore _recordingStore = RecordingStore.instance;

  // Loading state for pull-to-refresh
  final RxBool _isRefreshing = false.obs;
  bool get isRefreshing => _isRefreshing.value;

  // Computed property to check if library is empty
  bool get isLibraryEmpty =>
      recordingLibraryModelObj.value.recordingItemList.isEmpty;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();

    // Subscribe to RecordingStore stream
    _recordingSubscription = _recordingStore.stream.listen((items) {
      // items is List<RecordingItem>
      recordingLibraryModelObj.value.recordingItemList.assignAll(items);

      // Update recordings count
      recordingLibraryModelObj.value.recordingsCount?.value =
          '${items.length} recordings found';
    });

    // Load initial data
    _loadRecordings();
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// Load recordings from database
  Future<void> _loadRecordings() async {
    try {
      await _recordingStore.fetchAll();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load recordings: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  /// Pull-to-refresh handler
  Future<void> onRefresh() async {
    _isRefreshing.value = true;
    try {
      await _recordingStore.fetchAll();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh recordings: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Search functionality
  void onSearchTextChanged() {
    final searchTerm = searchController.text.toLowerCase();

    if (searchTerm.isEmpty) {
      // Reset to show all recordings
      _loadRecordings();
      return;
    }

    // Filter recordings based on search term
    final allRecordings = _recordingStore.list();
    final filteredRecordings = allRecordings.where((recording) {
      final titleMatch = recording.title.toLowerCase().contains(searchTerm);
      final summaryMatch =
          recording.summaryText?.toLowerCase().contains(searchTerm) ?? false;
      return titleMatch || summaryMatch;
    }).toList();

    // Update UI with filtered results
    recordingLibraryModelObj.value.recordingItemList
        .assignAll(filteredRecordings);
  }

  /// Navigate to Recording Summary Actions with recording ID
  void onOpenNotePressed(String recordingId) {
    // Ensure we have a valid recording ID
    if (recordingId.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid recording ID',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return;
    }

    // Navigate to Recording Summary Actions with recording ID
    Get.toNamed(
      AppRoutes.recordingSummaryScreen,
      arguments: {'recordingId': recordingId},
    );
  }

  /// Alternative method for opening recording note
  void onTapOpenNote(RecordingItem recording) {
    onOpenNotePressed(recording.id);
  }

  @override
  void onClose() {
    super.onClose();
    searchController.dispose();
    _recordingSubscription?.cancel();
  }
}