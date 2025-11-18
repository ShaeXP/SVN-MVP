import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_guard.dart';
import 'logger.dart';

/// Service for safely deleting recordings using hard delete via edge function
/// 
/// Uses the sv_delete_recording edge function which:
/// - Deletes summaries, notes, transcripts (best-effort, isolated failures)
/// - Deletes storage object
/// - Deletes the recording row
/// 
/// Schema notes:
/// - transcripts has ON DELETE CASCADE, but summaries does not
/// - Edge function manually deletes summaries to avoid FK issues
/// - This is a hard delete - the recording row is permanently removed
class RecordingDeleteService {
  static final RecordingDeleteService _instance = RecordingDeleteService._internal();
  factory RecordingDeleteService() => _instance;
  RecordingDeleteService._internal();

  final _supabase = Supabase.instance.client;

  /// Delete a recording using the sv_delete_recording edge function
  /// 
  /// This performs a hard delete:
  /// - Removes summaries, notes, transcripts, storage, and recording row
  /// - The edge function handles all cleanup in the correct order
  /// 
  /// Only deletes recordings that belong to the current user.
  /// Only deletes recordings that are in 'ready' or 'error' status.
  Future<void> deleteRecording(String recordingId) async {
    try {
      final session = AuthGuard.requireSessionOrBounce();
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // First, verify the recording exists and belongs to the user
      final recording = await _supabase
          .from('recordings')
          .select('id, status, user_id')
          .eq('id', recordingId)
          .eq('user_id', session.user.id)
          .maybeSingle();

      if (recording == null) {
        throw Exception('Recording not found or access denied');
      }

      // Only allow deletion of ready or error recordings
      final status = recording['status'] as String?;
      if (status != 'ready' && status != 'error') {
        throw Exception('Cannot delete recording that is still processing. Status: $status');
      }

      // Call the edge function to perform the deletion
      logx('[RecordingDeleteService] Calling sv_delete_recording for: $recordingId', tag: 'DELETE');
      final resp = await _supabase.functions.invoke(
        'sv_delete_recording',
        body: {
          'recordingId': recordingId,
        },
      );

      if (resp.status >= 300) {
        final errorData = resp.data as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Delete failed';
        final errorCode = errorData?['code'] ?? 'unknown';
        logx('[DELETE_RECORDING_ERROR] Edge function failed: status=${resp.status}, code=$errorCode, message=$errorMessage', tag: 'DELETE', error: errorMessage);
        throw Exception('Failed to delete recording: $errorMessage');
      }

      logx('[RecordingDeleteService] Successfully deleted recording: $recordingId', tag: 'DELETE');
    } catch (e) {
      logx('[DELETE_RECORDING_ERROR] Error deleting recording: $e', tag: 'DELETE', error: e);
      rethrow;
    }
  }
}

