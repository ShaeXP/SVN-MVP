import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/auth_guard.dart';

final supabase = Supabase.instance.client;

class RecordingItem {
  final String id;
  final String? title;
  final String status;
  final int? durationSec;
  RecordingItem({required this.id, this.title, required this.status, this.durationSec});
}

class LibraryController extends GetxController {
  final isLoading = true.obs;
  final error = ''.obs;
  final items = <RecordingItem>[].obs;
  
  Timer? _pollingTimer;
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
    super.onClose();
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
            summaries(title, created_at)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final data = (res as List).map((row) {
        // Get the latest summary title if available
        String? displayTitle;
        final summaries = row['summaries'] as List?;
        if (summaries != null && summaries.isNotEmpty) {
          // Sort by created_at desc and get the latest
          summaries.sort((a, b) {
            final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
            final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          displayTitle = summaries.first['title'] as String?;
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
        );
      }).toList();

      items.assignAll(data);
    } on PostgrestException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
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
}
