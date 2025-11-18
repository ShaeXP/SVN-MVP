// lib/services/status_transition_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth.dart';
import 'pipeline.dart';
import 'logger.dart';

class StatusTransitionService {
  static final _supabase = Supabase.instance.client;

  /// Handle Deepgram completion: transcript saved → set to 'summarizing' → trigger summarization
  static Future<void> handleTranscriptionComplete({
    required String recordingId,
    required String transcriptId,
  }) async {
    try {
      final userId = await AuthX.requireUserId();
      
      // Update recording status to 'summarizing'
      await _updateRecordingStatus(recordingId, userId, 'summarizing');
      
      logx('[STATUS] Transcription complete, starting summarization for recordingId: $recordingId, transcriptId: $transcriptId', 
           tag: 'PIPELINE');

      // Trigger summarization
      await Pipeline.summarizeRecording(recordingId);
      
      logx('[STATUS] Summarization triggered successfully for recordingId: $recordingId', 
           tag: 'PIPELINE');

    } catch (e) {
      logx('[STATUS] Failed to handle transcription complete for recordingId: $recordingId, transcriptId: $transcriptId', 
           tag: 'PIPELINE', 
           error: e);
      
      // Set status to error on failure
      try {
        final userId = await AuthX.requireUserId();
        await _updateRecordingStatus(recordingId, userId, 'error');
      } catch (_) {
        // If we can't even update status, log and continue
        logx('[STATUS] Failed to update status to error', 
             tag: 'PIPELINE', 
             error: e);
      }
      
      rethrow;
    }
  }

  /// Handle summarization completion: set to 'ready' or 'error'
  static Future<void> handleSummarizationComplete({
    required String recordingId,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      final userId = await AuthX.requireUserId();
      final status = success ? 'ready' : 'error';
      
      await _updateRecordingStatus(recordingId, userId, status);
      
      logx('[STATUS] Summarization complete for recordingId: $recordingId, success: $success, status: $status${errorMessage != null ? ', error: $errorMessage' : ''}', 
           tag: 'PIPELINE');

    } catch (e) {
      logx('[STATUS] Failed to handle summarization complete for recordingId: $recordingId, success: $success', 
           tag: 'PIPELINE', 
           error: e);
      rethrow;
    }
  }

  /// Update recording status in database
  static Future<void> _updateRecordingStatus(
    String recordingId, 
    String userId, 
    String status
  ) async {
    if (recordingId.isEmpty || userId.isEmpty) {
      throw Exception('Cannot update status: recordingId or userId is empty');
    }

    final response = await _supabase
        .from('recordings')
        .update({'status': status})
        .eq('id', recordingId)
        .eq('user_id', userId);

    if (response is Map && response['error'] != null) {
      throw Exception('Failed to update recording status: ${response['error']}');
    }

      logx('[STATUS] Updated recording status for recordingId: $recordingId, status: $status', 
           tag: 'PIPELINE');
  }

  /// Validate status transition is allowed
  static bool isValidTransition(String fromStatus, String toStatus) {
    const validTransitions = {
      'local': ['uploading', 'error'],
      'uploading': ['transcribing', 'error'],
      'transcribing': ['summarizing', 'error'],
      'summarizing': ['ready', 'error'],
      'ready': [], // Terminal state
      'error': [], // Terminal state
    };

    return validTransitions[fromStatus]?.contains(toStatus) ?? false;
  }

  /// Get status display information for UI
  static StatusDisplayInfo getStatusDisplayInfo(String status) {
    // Normalize status to lowercase for consistent matching
    final normalizedStatus = status.toLowerCase().trim();
    
    switch (normalizedStatus) {
      case 'local':
        return StatusDisplayInfo(
          label: 'Local',
          color: Colors.grey,
          icon: Icons.radio_button_unchecked,
          canOpenSummary: false,
        );
      case 'uploading':
        return StatusDisplayInfo(
          label: 'Uploading…',
          color: Colors.blue,
          icon: Icons.cloud_upload,
          canOpenSummary: false,
        );
      case 'uploaded':
        return StatusDisplayInfo(
          label: 'Ready',
          color: Colors.green,
          icon: Icons.check_circle,
          canOpenSummary: true,
        );
      case 'transcribing':
        return StatusDisplayInfo(
          label: 'Transcribing…',
          color: Colors.orange,
          icon: Icons.mic,
          canOpenSummary: false,
        );
      case 'summarizing':
        return StatusDisplayInfo(
          label: 'Summarizing…',
          color: Colors.purple,
          icon: Icons.auto_awesome,
          canOpenSummary: false,
        );
      case 'ready':
        return StatusDisplayInfo(
          label: 'Ready',
          color: Colors.green,
          icon: Icons.check_circle,
          canOpenSummary: true,
        );
      case 'error':
        return StatusDisplayInfo(
          label: 'Error',
          color: Colors.red,
          icon: Icons.error,
          canOpenSummary: false,
        );
      // Handle common variations and edge cases
      case 'processing':
      case 'in_progress':
        return StatusDisplayInfo(
          label: 'Processing…',
          color: Colors.blue,
          icon: Icons.hourglass_empty,
          canOpenSummary: false,
        );
      case 'pending':
        return StatusDisplayInfo(
          label: 'Pending',
          color: Colors.amber,
          icon: Icons.schedule,
          canOpenSummary: false,
        );
      case 'completed':
      case 'done':
        return StatusDisplayInfo(
          label: 'Ready',
          color: Colors.green,
          icon: Icons.check_circle,
          canOpenSummary: true,
        );
      case 'failed':
        return StatusDisplayInfo(
          label: 'Error',
          color: Colors.red,
          icon: Icons.error,
          canOpenSummary: false,
        );
      default:
        // Log unknown status for debugging
        logx('[STATUS_CHIP] Unknown status received: "$status" (normalized: "$normalizedStatus")', tag: 'STATUS');
        return StatusDisplayInfo(
          label: 'Processing…', // Show a more user-friendly label instead of raw status
          color: Colors.blue,
          icon: Icons.hourglass_empty,
          canOpenSummary: false,
        );
    }
  }
}

class StatusDisplayInfo {
  final String label;
  final Color color;
  final IconData icon;
  final bool canOpenSummary;

  const StatusDisplayInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.canOpenSummary,
  });
}
