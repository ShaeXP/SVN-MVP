import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/auth_guard.dart';
import '../../utils/error_message_helper.dart';
import '../../services/recording_delete_service.dart';
import '../home_screen/controller/home_controller.dart';

final supabase = Supabase.instance.client;

class RecordingItem {
  final String id;
  final String? title;
  final String status;
  final int? durationSec;
  final String? preview; // Preview text shown on Home and Library cards comes from summaries.summary
  RecordingItem({
    required this.id,
    this.title,
    required this.status,
    this.durationSec,
    this.preview,
  });
}

class LibraryController extends GetxController {
  final isLoading = true.obs;
  final error = ''.obs;
  final items = <RecordingItem>[].obs;
  final searchQuery = ''.obs;
  final recentlyCreatedRecordingId = RxString('');
  
  Timer? _pollingTimer;
  Timer? _highlightTimer;
  int _pollingBackoff = 10; // seconds

  @override
  void onInit() {
    super.onInit();
    fetch();
    startPolling();
  }

  @override
  void onClose() {
    stopPolling();
    _highlightTimer?.cancel();
    _highlightTimer = null;
    super.onClose();
  }
  
  /// Mark a recording as recently created for highlighting
  void markRecordingAsRecentlyCreated(String recordingId) {
    recentlyCreatedRecordingId.value = recordingId;
    
    // Clear highlight after 8 seconds
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 8), () {
      if (recentlyCreatedRecordingId.value == recordingId) {
        recentlyCreatedRecordingId.value = '';
      }
    });
  }

  /// Derived list that applies a simple text search over title and summary preview.
  /// Type-agnostic: does not filter by summary style/type.
  List<RecordingItem> get filteredItems {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((item) {
      final title = (item.title ?? '').toLowerCase();
      final previewText = (item.preview ?? '').toLowerCase();
      final combined = '$title $previewText';
      return combined.contains(q);
    }).toList();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = '';
    try {
      final session = AuthGuard.requireSessionOrBounce();
      if (session == null) {
        items.clear();
        return;
      }
      final user = session.user;

      final res = await supabase
          .from('recordings')
          .select('''
            id,
            status,
            duration_sec,
            storage_path,
            created_at,
            summaries(title, summary, created_at)
          ''')
          .eq('user_id', user.id)
          // Note: Using hard delete via edge function, so no deleted_at filter needed
          // Deleted recordings are permanently removed and won't appear in queries
          .order('created_at', ascending: false);

      final data = (res as List).map((row) {
        // Get the latest summary title and preview if available
        String? displayTitle;
        String? previewText;
        final summaries = row['summaries'] as List?;
        if (summaries != null && summaries.isNotEmpty) {
          // Sort by created_at desc and get the latest
          summaries.sort((a, b) {
            final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
            final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          final latestSummary = summaries.first;
          displayTitle = latestSummary['title'] as String?;
          // Preview text shown on Home and Library cards comes from summaries.summary
          previewText = latestSummary['summary'] as String?;
        }
        
        // Fallback to derived name if no summary title
        if (displayTitle == null || displayTitle.isEmpty) {
          final storagePath = row['storage_path'] as String? ?? '';
          final fileName = storagePath.split('/').last.split('.').first;
          final createdAt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
          
          if (fileName.isNotEmpty) {
            displayTitle = fileName;
          } else {
            // Friendly date format: "Recording — Jan 15, 2:30 PM"
            final month = _getMonthName(createdAt.month);
            final hour = createdAt.hour > 12 ? createdAt.hour - 12 : createdAt.hour;
            final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
            final minute = createdAt.minute.toString().padLeft(2, '0');
            displayTitle = 'Recording — $month ${createdAt.day}, $hour:$minute $ampm';
          }
        }

        return RecordingItem(
          id: row['id'] as String,
          title: displayTitle,
          status: (row['status'] as String?) ?? 'processing',
          durationSec: row['duration_sec'] as int?,
          preview: previewText,
        );
      }).toList();

      items.assignAll(data);
    } on PostgrestException catch (e, st) {
      // TEMP: log full error & stack for debugging
      debugPrint('[LIBRARY_FETCH_ERROR] PostgrestException: $e');
      debugPrint('[LIBRARY_FETCH_STACK] $st');
      debugPrint('[LIBRARY_FETCH_MESSAGE] ${e.message}');
      debugPrint('[LIBRARY_FETCH_CODE] ${e.code}');
      error.value = ErrorMessageHelper.getUserFriendlyMessage(e);
    } catch (e, st) {
      // TEMP: log full error & stack for debugging
      debugPrint('[LIBRARY_FETCH_ERROR] Exception: $e');
      debugPrint('[LIBRARY_FETCH_STACK] $st');
      error.value = ErrorMessageHelper.getUserFriendlyMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await fetch();
  }

  void startPolling() {
    stopPolling(); // Clear any existing timer
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingBackoff), (timer) {
      _pollingTick();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _pollingTick() async {
    // Only poll if there are items with active statuses
    final hasActiveItems = items.any((item) => 
      ['uploading', 'transcribing', 'summarizing'].contains(item.status));
    
    if (!hasActiveItems) {
      stopPolling();
      return;
    }

    // Fetch updates
    await fetch();
    
    // Implement backoff: if no changes after 3 ticks, slow down
    if (_pollingBackoff == 10) {
      _pollingBackoff = 20;
      startPolling(); // Restart with new interval
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  /// Delete a recording (hard delete via edge function)
  /// Removes it from the local list optimistically, then performs the deletion
  /// Also refreshes HomeController to keep both screens in sync
  Future<void> deleteRecording(String recordingId) async {
    try {
      // Optimistic update: remove from local list first
      items.removeWhere((item) => item.id == recordingId);
      
      // Perform deletion via edge function
      await RecordingDeleteService().deleteRecording(recordingId);
      
      // Refresh HomeController to keep Home and Library in sync
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          await homeController.refresh();
        }
      } catch (e) {
        // HomeController might not be registered yet, that's okay
        debugPrint('[LIBRARY] Could not refresh HomeController: $e');
      }
    } catch (e) {
      // On error, refresh the list to restore the item
      await fetch();
      rethrow;
    }
  }
}
