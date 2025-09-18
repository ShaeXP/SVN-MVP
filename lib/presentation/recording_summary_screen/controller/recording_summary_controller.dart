import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../services/summary_backend_service.dart';
import '../models/recording_summary_model.dart';

class RecordingSummaryController extends GetxController {
  Rx<RecordingSummaryModel> recordingSummaryModelObj =
      RecordingSummaryModel().obs;

  // State machine states
  RxString status = 'loading'.obs;

  // Data from backend
  Rx<Map<String, dynamic>?> noteRun = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> runEvents = <Map<String, dynamic>>[].obs;

  String? runId;
  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _noteRunSubscription;
  StreamSubscription<Map<String, dynamic>>? _runEventsSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Read run_id from route arguments
      final args = ModalRoute.of(Get.context!)!.settings.arguments;
      runId = (args is Map && args['run_id'] is String)
          ? args['run_id'] as String
          : null;

      if (runId == null) {
        status.value = 'error: missing run_id';
        return;
      }

      await _initializeData();
      _startRealTimeUpdates();
      _startPolling();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Fetch initial data
      final noteRunData =
          await SummaryBackendService.instance.getNoteRun(runId!);
      final events = await SummaryBackendService.instance.getRunEvents(runId!);

      noteRun.value = noteRunData;
      runEvents.value = events;

      _updateStatus();
    } catch (e) {
      status.value = 'error: $e';
    }
  }

  void _startRealTimeUpdates() {
    // Subscribe to note_runs changes
    _noteRunSubscription = SummaryBackendService.instance
        .subscribeToNoteRun(runId!)
        .listen((data) {
      if (data.isNotEmpty) {
        noteRun.value = data;
        _updateStatus();
      }
    });

    // Subscribe to run_events changes
    _runEventsSubscription = SummaryBackendService.instance
        .subscribeToRunEvents(runId!)
        .listen((data) {
      if (data.isNotEmpty) {
        final existingIds = runEvents.map((e) => e['id']).toSet();
        if (!existingIds.contains(data['id'])) {
          runEvents.add(data);
          _updateStatus();
        }
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (status.value == 'ready' || status.value.startsWith('error')) {
        timer.cancel();
        return;
      }

      try {
        final noteRunData =
            await SummaryBackendService.instance.getNoteRun(runId!);
        final events =
            await SummaryBackendService.instance.getRunEvents(runId!);

        if (noteRunData != null) {
          noteRun.value = noteRunData;
        }
        runEvents.value = events;

        _updateStatus();

        // If we have transcript but no summary, try to generate summary
        if (noteRun.value != null &&
            noteRun.value!['transcript_text'] != null &&
            noteRun.value!['summary_v1'] == null &&
            !status.value.contains('summarizing')) {
          await _triggerSummarization();
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  Future<void> _triggerSummarization() async {
    try {
      status.value = 'summarizing';

      // Try sv_summarize_run first
      final summaryResult =
          await SummaryBackendService.instance.callSummarizeRun(runId!);

      if (summaryResult == null || summaryResult['success'] != true) {
        // Fallback to summarize-transcript
        final transcriptText = noteRun.value?['transcript_text'] as String?;
        if (transcriptText != null && transcriptText.trim().isNotEmpty) {
          await SummaryBackendService.instance
              .callSummarizeTranscript(transcriptText);
        }
      }

      // Refresh data after summarization attempt
      await Future.delayed(Duration(seconds: 2));
      final updatedNoteRun =
          await SummaryBackendService.instance.getNoteRun(runId!);
      if (updatedNoteRun != null) {
        noteRun.value = updatedNoteRun;
        _updateStatus();
      }
    } catch (e) {
      debugPrint('Summarization error: $e');
    }
  }

  void _updateStatus() {
    final newStatus =
        SummaryBackendService.instance.determineState(noteRun.value, runEvents);

    if (newStatus != status.value) {
      status.value = newStatus;
      debugPrint('Status updated to: $newStatus');
    }
  }

  // UI Getters
  String get currentState => status.value;

  String get audioUrl => noteRun.value?['audio_url'] ?? '';

  String get summaryText {
    final summary = noteRun.value?['summary_v1'];
    if (summary is Map) {
      final tldr = summary['tl_dr'] as String?;
      if (tldr != null && tldr.isNotEmpty) return tldr;

      final title = summary['title'] as String?;
      if (title != null && title.isNotEmpty) return title;
    }
    return 'Summary not generated yet.';
  }

  List<String> get keyPoints {
    final summary = noteRun.value?['summary_v1'];
    if (summary is Map) {
      final keyPoints = summary['key_points'];
      if (keyPoints is List) {
        return keyPoints.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  List<String> get actionItems {
    final summary = noteRun.value?['summary_v1'];
    if (summary is Map) {
      final actionItems = summary['action_items'];
      if (actionItems is List) {
        return actionItems.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  String get rawTranscriptJson {
    final transcriptText = noteRun.value?['transcript_text'] as String?;
    if (transcriptText != null && transcriptText.isNotEmpty) {
      return transcriptText;
    }
    return 'No transcript available';
  }

  String get stateMessage {
    switch (status.value) {
      case 'loading':
        return 'Initializing...';
      case 'transcribing':
        return 'Transcribing audio...';
      case 'summarizing':
        return 'Generating summary...';
      case 'ready':
        return 'Summary ready';
      default:
        if (status.value.startsWith('error')) {
          return status.value.replaceFirst('error: ', '');
        }
        return 'Processing...';
    }
  }

  // Manual retry method
  Future<void> retry() async {
    status.value = 'loading';
    await _initializeData();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _noteRunSubscription?.cancel();
    _runEventsSubscription?.cancel();
    super.onClose();
  }
}

extension ListObservable on List<String> {
  RxList<String> asObservable() {
    return RxList<String>.from(this);
  }
}
