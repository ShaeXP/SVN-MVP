import 'package:supabase_flutter/supabase_flutter.dart';

class UseRunsList {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream for realtime updates
  Stream<List<Map<String, dynamic>>>? _runsStream;

  /// Query runs from note_runs table
  Future<List<Map<String, dynamic>>> fetchRuns() async {
    try {
      final response = await _supabase
          .from('note_runs')
          .select(
            'id, user_id, created_at, status, summary_v1, duration_s, audio_url, transcript_text',
          )
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch runs: $e');
    }
  }

  /// Get realtime stream for runs
  Stream<List<Map<String, dynamic>>> getRunsStream() {
    _runsStream ??= _supabase
        .from('note_runs')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return _runsStream!;
  }

  /// Delete a run and its audio file
  Future<void> deleteRun(String runId, String? audioPath) async {
    try {
      // Delete from database (RLS will handle user_id filtering)
      await _supabase
          .from('note_runs')
          .delete()
          .match({'id': runId, 'user_id': _supabase.auth.currentUser!.id});

      // Try to delete audio file if path exists (ignore errors)
      if (audioPath != null && audioPath.isNotEmpty) {
        try {
          await _supabase.storage.from('audio').remove([audioPath]);
        } catch (e) {
          // Ignore 404 or other storage errors as requested
        }
      }
    } catch (e) {
      throw Exception('Failed to delete run: $e');
    }
  }

  /// Format duration from seconds to mm:ss
  static String formatDuration(int durationSeconds) {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get status badge text
  static String getStatusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return 'Queued';
      case 'transcribing':
        return 'Transcribing';
      case 'transcribed':
        return 'Transcribed';
      case 'summarized':
        return 'Ready';
      case 'error':
        return 'Error';
      default:
        return status;
    }
  }

  /// Extract title from summary_v1 JSON or provide fallback
  static String getTitleFromSummary(Map<String, dynamic>? summaryV1) {
    if (summaryV1 != null && summaryV1['title'] is String) {
      return summaryV1['title'] as String;
    }
    return 'Transcript processing…';
  }
}
