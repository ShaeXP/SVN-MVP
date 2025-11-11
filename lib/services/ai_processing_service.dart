import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:record/record.dart';

import '../core/utils/preview_mode_detector.dart';
import '../data/models/recording_item.dart';
import './openai_service.dart';
import './recording_store.dart';
import './supabase_service.dart';
import './auth.dart';

class AIProcessingService {
  static final AIProcessingService _instance = AIProcessingService._internal();
  late final OpenAIService _openAIService;
  late final SupabaseService _supabaseService;
  late final AudioRecorder _recorder;

  factory AIProcessingService() {
    return _instance;
  }

  AIProcessingService._internal() {
    _openAIService = OpenAIService();
    _supabaseService = SupabaseService.instance;
    _recorder = AudioRecorder();
  }

  /// Complete AI processing pipeline for recordings with preview mode support
  /// 1. Upload audio file to Supabase storage
  /// 2. Transcribe using OpenAI Whisper (AssemblyAI alternative)
  /// 3. Generate summary using OpenAI GPT-4
  /// 4. Save results to database
  Future<ProcessingResult> processRecording({
    required String recordingId,
    required File audioFile,
    String? recordingTitle,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('ðŸŽ­ Preview mode: Mock AI processing pipeline');
      return await _mockProcessRecording(
        recordingId: recordingId,
        audioFile: audioFile,
        recordingTitle: recordingTitle,
      );
    }

    try {
      // Step 1: Upload to Supabase Storage
      final audioUrl = await _uploadAudioFile(audioFile, recordingId);

      // Step 2: Transcribe audio using OpenAI Whisper
      final transcript = await _openAIService.transcribeAudio(
        audioFile: audioFile,
        model: 'whisper-1',
        responseFormat: 'json',
      );

      if (transcript.isEmpty) {
        throw AIProcessingException('Failed to transcribe audio');
      }

      // Step 3: Generate AI summary using OpenAI GPT-4
      final aiSummary = await _openAIService.generateSummary(
        transcriptText: transcript,
        model: 'gpt-4o-mini',
      );

      // Step 4: Update recording in database
      await _updateRecordingWithResults(
        recordingId: recordingId,
        audioUrl: audioUrl,
        transcript: transcript,
        summary: aiSummary.summaryText,
        title: recordingTitle,
      );

      // Step 5: Create or update notes entry
      await _createNotesEntry(
        recordingId: recordingId,
        transcript: transcript,
        summary: aiSummary.summaryText,
        actions: aiSummary.actions,
        keypoints: aiSummary.keypoints,
        title: recordingTitle ?? 'AI Generated Summary',
      );

      // Step 6: Update RecordingStore with AI-generated data
      final recordingItem = RecordingItem(
        id: recordingId,
        title: recordingTitle ??
            'Recording ${DateTime.now().toIso8601String().substring(0, 16)}',
        date: _formatCurrentDate(),
        duration: await _getAudioDuration(audioFile),
        summaryText: aiSummary.summaryText,
        actions: aiSummary.actions,
        keypoints: aiSummary.keypoints,
      );

      // Clear mock data and add real data
      RecordingStore().clear();
      RecordingStore().add(recordingItem);

      return ProcessingResult(
        success: true,
        recordingItem: recordingItem,
        audioUrl: audioUrl,
        transcript: transcript,
      );
    } catch (e) {
      return ProcessingResult(
        success: false,
        error: 'Processing failed: $e',
        fallbackMessage: 'Summary not available. Please retry later.',
      );
    }
  }

  /// Mock processing for preview mode
  Future<ProcessingResult> _mockProcessRecording({
    required String recordingId,
    required File audioFile,
    String? recordingTitle,
  }) async {
    // Simulate processing delay
    await Future.delayed(Duration(seconds: 1));

    // Generate mock AI summary
    final aiSummary = await _openAIService.generateSummary(
      transcriptText: 'Mock transcript for preview mode',
    );

    final recordingItem = RecordingItem(
      id: recordingId,
      title: recordingTitle ??
          'Preview Recording ${DateTime.now().toString().substring(11, 16)}',
      date: _formatCurrentDate(),
      duration: await _getAudioDuration(audioFile),
      summaryText: aiSummary.summaryText,
      actions: aiSummary.actions,
      keypoints: aiSummary.keypoints,
    );

    // Update RecordingStore with mock data
    RecordingStore().clear();
    RecordingStore().add(recordingItem);

    return ProcessingResult(
      success: true,
      recordingItem: recordingItem,
      audioUrl: 'preview-audio-url',
      transcript:
          'Mock transcript for preview mode. This demonstrates the transcription feature.',
    );
  }

  /// Upload audio file to Supabase storage (recordings bucket)
  Future<String> _uploadAudioFile(File audioFile, String recordingId) async {
    try {
      if (recordingId.isEmpty) {
        throw AIProcessingException('Cannot upload audio file with empty recordingId');
      }

      final userId = await AuthX.requireUserId();
      final fileName =
          '${recordingId}_${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(audioFile.path)}';
      final filePath = '$userId/$fileName';

      final response = await _supabaseService.client.storage
          .from('recordings')
          .upload(filePath, audioFile);

      // Get public URL
      final publicUrl = _supabaseService.client.storage
          .from('recordings')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw AIProcessingException('Failed to upload audio file: $e');
    }
  }

  /// Update recording in database with processing results
  Future<void> _updateRecordingWithResults({
    required String recordingId,
    required String audioUrl,
    required String transcript,
    required String summary,
    String? title,
  }) async {
    try {
      if (recordingId.isEmpty) {
        throw AIProcessingException('Cannot update recording with empty ID');
      }

      final userId = await AuthX.requireUserId();
      final updateMap = {
        'url': audioUrl,
        'transcript': transcript,
        'summary': summary,
        'status': 'processed',
        'updated_at': DateTime.now().toIso8601String(),
        if (title != null) 'title': title,
      };
      updateMap.removeWhere((k, v) => v == null);
      updateMap.remove('title');
      updateMap.remove('trace_id');
      await SupabaseService.instance.client.from('recordings').update(updateMap).eq('id', recordingId).eq('user_id', userId);
    } catch (e) {
      throw AIProcessingException('Failed to update recording: $e');
    }
  }

  /// Create notes entry with AI-generated content
  Future<void> _createNotesEntry({
    required String recordingId,
    required String transcript,
    required String summary,
    required List<String> actions,
    required List<String> keypoints,
    required String title,
  }) async {
    try {
      if (recordingId.isEmpty) {
        throw AIProcessingException('Cannot create notes entry with empty recordingId');
      }

      final userId = await AuthX.requireUserId();
      await SupabaseService.instance.client.from('notes').insert({
        'recording_id': recordingId,
        'user_id': userId,
        'title': title,
        'transcript': transcript,
        'summary': summary,
        'actions': actions,
        'highlights': keypoints,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw AIProcessingException('Failed to create notes entry: $e');
    }
  }

  /// Get file extension from file path
  String _getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Format current date for display
  String _formatCurrentDate() {
    final now = DateTime.now();
    final hours =
        now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return "${now.month}/${now.day}/${now.year} ${hours}:${now.minute.toString().padLeft(2, '0')} ${amPm}";
  }

  /// Get audio duration (mock implementation - you may want to use a proper audio package)
  Future<String> _getAudioDuration(File audioFile) async {
    try {
      // For now, return a mock duration
      // You can use packages like 'audioplayers' or 'just_audio' for actual duration calculation
      final fileSizeInBytes = await audioFile.length();
      final estimatedDurationSeconds =
          (fileSizeInBytes / 32000).round(); // Rough estimate

      final minutes = estimatedDurationSeconds ~/ 60;
      final seconds = estimatedDurationSeconds % 60;
      return "${minutes}:${seconds.toString().padLeft(2, '0')}";
    } catch (e) {
      return "0:00";
    }
  }
}

class ProcessingResult {
  final bool success;
  final RecordingItem? recordingItem;
  final String? audioUrl;
  final String? transcript;
  final String? error;
  final String? fallbackMessage;

  ProcessingResult({
    required this.success,
    this.recordingItem,
    this.audioUrl,
    this.transcript,
    this.error,
    this.fallbackMessage,
  });
}

class AIProcessingException implements Exception {
  final String message;

  AIProcessingException(this.message);

  @override
  String toString() => 'AIProcessingException: $message';
}
