import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';
import '../../../features/library/use_runs_list.dart';
import '../models/recording_library_model.dart';

class RecordingLibraryController extends GetxController {
  late TextEditingController searchController;

  /// Reactive UI model
  final Rx<RecordingLibraryModel> recordingLibraryModelObj =
      RecordingLibraryModel().obs;

  /// Data source (Supabase-backed service)
  final UseRunsList _useRunsList = UseRunsList();

  /// Live updates
  StreamSubscription<List<Map<String, dynamic>>>? _runsSubscription;

  /// Raw rows from DB
  final RxList<Map<String, dynamic>> _runs = <Map<String, dynamic>>[].obs;

  /// Loading/error state
  final RxBool _isRefreshing = false.obs;
  bool get isRefreshing => _isRefreshing.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;

  /// Empty-state computed
  bool get isLibraryEmpty => _runs.isEmpty && !_isRefreshing.value && !hasError;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();

    _subscribeToRuns(); // realtime (safe)
    _loadRuns();        // initial fetch (safe)
  }

  @override
  void onReady() {
    super.onReady();
  }

  // -----------------------------
  // Data wiring
  // -----------------------------

  /// Subscribe to realtime updates from the backend.
  void _subscribeToRuns() {
    try {
      _runsSubscription = _useRunsList.getRunsStream().listen(
        (runs) {
          // Service should deliver a list; guard anyway
          final safe = (runs ?? const <Map<String, dynamic>>[])
              .whereType<Map<String, dynamic>>()
              .toList();

          _runs.assignAll(safe);
          _errorMessage.value = '';
          _updateRecordingsList();
        },
        onError: (error) {
          _errorMessage.value = _friendlyError('Realtime error', error);
          Get.snackbar(
            'Connection issue',
            'Lost connection. Pull to refresh.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: appTheme.orange_900,
            colorText: appTheme.white_A700,
          );
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      _errorMessage.value = _friendlyError('Failed to setup realtime', e);
      debugPrintStack(label: 'subscribeToRuns', stackTrace: st);
    }
  }

  /// One-shot load (used by init + pull-to-refresh + retry).
  Future<void> _loadRuns() async {
    try {
      _errorMessage.value = '';
      final rows = await _useRunsList.fetchRuns();

      // Guard null/ill-typed results from the service
      final safe = (rows ?? const <Map<String, dynamic>>[])
          .whereType<Map<String, dynamic>>()
          .toList();

      _runs.assignAll(safe);
      _updateRecordingsList();
    } catch (e, st) {
      _errorMessage.value = _friendlyError('Failed to load recordings', e);
      debugPrintStack(label: 'loadRuns', stackTrace: st);

      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  /// Map raw rows -> UI list model (defensive).
  void _updateRecordingsList() {
    final filteredRuns = _filterRuns(_runs);

    final recordingItems = filteredRuns.map<RecordingItem>((run) {
      // Safe field extraction
      final id = (run['id'] ?? '').toString();

      final createdRaw = run['created_at']?.toString();
      final createdAt = DateTime.tryParse(createdRaw ?? '');

      final durationS = (run['duration_s'] as num?)?.toInt() ?? 0;

      final summaryV1 = run['summary_v1'];
      final Map<String, dynamic>? summaryMap =
          summaryV1 is Map<String, dynamic> ? summaryV1 : null;

      return RecordingItem(
        id: id,
        title: UseRunsList.getTitleFromSummary(summaryMap),
        date: createdAt != null
            ? UseRunsList.getRelativeTime(createdAt)
            : '—',
        duration: durationS > 0
            ? UseRunsList.formatDuration(durationS)
            : '',
        summaryText: summaryMap?['title'] as String?,
      );
    }).toList();

    final model = recordingLibraryModelObj.value;
    model.recordingItemList
      ..clear()
      ..addAll(recordingItems);

    // Update count label if present in your model
    if (model.recordingsCount != null) {
      model.recordingsCount!.value =
          '${recordingItems.length} recordings found';
    }

    // Push change
    recordingLibraryModelObj.refresh();
  }

  // -----------------------------
  // UI actions
  // -----------------------------

  /// Pull-to-refresh handler
  Future<void> onRefresh() async {
    _isRefreshing.value = true;
    try {
      await _loadRuns();
    } catch (e) {
      Get.snackbar(
        'Error',
        _friendlyError('Failed to refresh recordings', e),
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Retry button
  Future<void> onRetry() => onRefresh();

  /// Search text changed
  void onSearchTextChanged() => _updateRecordingsList();

  /// Navigate to the Recording Summary screen.
  /// Prefers transcript_id when available; falls back to run_id.
  void onOpenNotePressed(String recordingId) {
    if (recordingId.isEmpty) {
      Get.snackbar(
        'Invalid note',
        'Missing recording ID.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return;
    }

    final run = _runs.firstWhere(
      (r) => (r['id']?.toString() ?? '') == recordingId,
      orElse: () => <String, dynamic>{},
    );

    final args = <String, dynamic>{};
    final transcriptText = run['transcript_text'] as String?;
    if (transcriptText != null && transcriptText.isNotEmpty) {
      args['transcript_id'] = recordingId;
    } else {
      args['run_id'] = recordingId;
    }

    Get.toNamed(AppRoutes.recordingSummaryScreen, arguments: args);
  }

  /// Delete a recording with confirmation (defensive).
  Future<void> onDeletePressed(String recordingId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This will remove the transcript and audio.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: TextStyle(color: appTheme.red_400)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final run = _runs.firstWhere(
        (r) => (r['id']?.toString() ?? '') == recordingId,
        orElse: () => <String, dynamic>{},
      );

      final audioUrl = run['audio_url'] as String?;
      String? audioPath;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final uri = Uri.tryParse(audioUrl);
        if (uri != null && uri.pathSegments.length > 3) {
          audioPath = uri.pathSegments.skip(3).join('/');
        }
      }

      // Optimistic UI update
      _runs.removeWhere((r) => (r['id']?.toString() ?? '') == recordingId);
      _updateRecordingsList();

      // Backend delete
      await _useRunsList.deleteRun(recordingId, audioPath);

      Get.snackbar(
        'Deleted',
        'Recording deleted.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.green_600,
        colorText: appTheme.white_A700,
      );
    } catch (e, st) {
      // Restore UI from backend on failure
      await _loadRuns();
      debugPrintStack(label: 'deleteRun', stackTrace: st);

      Get.snackbar(
        'Error',
        _friendlyError('Failed to delete recording', e),
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
  }

  /// Convenience for item taps elsewhere
  void onTapOpenNote(RecordingItem recording) =>
      onOpenNotePressed(recording.id);

  // -----------------------------
  // Helpers
  // -----------------------------

  List<Map<String, dynamic>> _filterRuns(List<Map<String, dynamic>> runs) {
    final q = searchController.text.toLowerCase().trim();
    if (q.isEmpty) return runs;

    return runs.where((run) {
      final Map<String, dynamic>? s =
          run['summary_v1'] is Map<String, dynamic>
              ? run['summary_v1'] as Map<String, dynamic>
              : null;

      final title = UseRunsList.getTitleFromSummary(s).toLowerCase();
      final transcript = (run['transcript_text'] as String? ?? '').toLowerCase();

      return title.contains(q) || transcript.contains(q);
    }).toList();
  }

  String _friendlyError(String prefix, Object e) {
    final msg = e.toString();
    if (msg.contains('Null check operator used on a null value')) {
      // Typical when the service or DB returns null unexpectedly (preview/no data)
      return '$prefix: data unavailable. Try again after adding a recording.';
    }
    return '$prefix: $msg';
  }

  @override
  void onClose() {
    searchController.dispose();
    _runsSubscription?.cancel();
    super.onClose();
  }
}