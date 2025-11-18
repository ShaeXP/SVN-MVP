import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:file_picker/file_picker.dart';

import './authoritative_upload_service.dart';
import './pipeline_tracker.dart';
import './pipeline_service.dart';

class FileUploadService {
  static FileUploadService? _instance;
  static FileUploadService get instance => _instance ??= FileUploadService._();

  FileUploadService._();

  final AuthoritativeUploadService _uploadService = AuthoritativeUploadService();

  /// Pick and upload audio file with authoritative pipeline
  Future<Map<String, dynamic>> pickAndUploadAudioFile({ String? summaryStyleOverride }) async {
    try {
      debugPrint('📁 Starting file picker for audio upload...');

      // Step 1: Pick audio or transcript file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webm', 'm4a', 'wav', 'mp3', 'aac', 'txt', 'json', 'srt', 'vtt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return {
          'success': false,
          'error': 'No file selected',
          'message': 'File selection was cancelled'
        };
      }

      final PlatformFile file = result.files.first;
      debugPrint('✅ File selected: ${file.name} (${file.size} bytes)');

      // Validate file extension
      final String fileName = file.name.toLowerCase();
      final bool isAudio = fileName.endsWith('.webm') || fileName.endsWith('.m4a') || 
                          fileName.endsWith('.wav') || fileName.endsWith('.mp3') || 
                          fileName.endsWith('.aac');
      final bool isTranscript = fileName.endsWith('.txt') || fileName.endsWith('.json') || 
                               fileName.endsWith('.srt') || fileName.endsWith('.vtt');
      
      if (!isAudio && !isTranscript) {
        return {
          'success': false,
          'error': 'Invalid file format',
          'message': 'Please select an audio file (.webm, .m4a, .wav, .mp3, .aac) or transcript file (.txt, .json, .srt, .vtt)'
        };
      }

      // Step 2: Get file bytes
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        if (file.path != null) {
          final ioFile = File(file.path!);
          fileBytes = await ioFile.readAsBytes();
        }
      }

      if (fileBytes == null) {
        return {
          'success': false,
          'error': 'Could not read file',
          'message': 'Failed to read the selected file'
        };
      }

      // Step 3: Estimate duration (simplified estimation based on file size)
      // For more accurate duration, you would need audio processing libraries
      final int estimatedDurationMs = _estimateAudioDuration(file.size);

      // Step 4: Handle audio vs transcript files differently
      Map<String, dynamic> uploadResult;
      
      if (isAudio) {
        // Audio file - use existing authoritative upload flow
        uploadResult = await _uploadService.uploadWithAuthoritativeFlow(
          fileBytes: fileBytes,
          originalFilename: file.name,
          durationMs: estimatedDurationMs,
          summaryStyleOverride: summaryStyleOverride,
          onFunctionInvoke: () {
            // Notify PipelineTracker that function invoke started
            PipelineTracker.I.markInvokeStarted();
          },
        );
      } else {
        // Transcript file - parse and upload as transcript
        uploadResult = await _handleTranscriptUpload(file, fileBytes);
      }

      if (uploadResult['success']) {
        debugPrint('✅ File upload completed successfully');
        return {
          ...uploadResult,
          'file_name': file.name,
          'file_size': file.size,
        };
      } else {
        debugPrint('❌ File upload failed: ${uploadResult['error']}');
        return uploadResult;
      }
    } catch (e) {
      debugPrint('❌ File upload service error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'File upload failed due to an unexpected error'
      };
    }
  }

  /// Simplified duration estimation based on file size
  /// This is a rough estimate - for accurate duration, use audio processing libraries
  int _estimateAudioDuration(int fileSizeBytes) {
    // Rough estimation: assume 128kbps average bitrate for compressed audio
    // 128kbps = 16,000 bytes per second
    const int avgBytesPerSecond = 16000;
    final int estimatedSeconds = fileSizeBytes ~/ avgBytesPerSecond;
    return estimatedSeconds * 1000; // Convert to milliseconds
  }

  /// Validate if file is a supported audio format
  bool isSupportedAudioFile(String fileName) {
    final String lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.webm') ||
        lowerName.endsWith('.m4a') ||
        lowerName.endsWith('.wav') ||
        lowerName.endsWith('.mp3') ||
        lowerName.endsWith('.aac');
  }

  /// Get supported file extensions for UI display
  List<String> get supportedExtensions =>
      ['.webm', '.m4a', '.wav', '.mp3', '.aac', '.txt', '.json', '.srt', '.vtt'];

  /// Parse transcript from various file formats
  Future<String> _parseTranscript(PlatformFile file, Uint8List fileBytes) async {
    final fileName = file.name.toLowerCase();
    final content = utf8.decode(fileBytes);
    
    if (fileName.endsWith('.txt')) {
      // Plain text file
      return content.trim();
    }
    
    if (fileName.endsWith('.json')) {
      // Deepgram JSON format
      try {
        final json = jsonDecode(content);
        // Try to get transcript from Deepgram format
        if (json['results'] != null && 
            json['results']['channels'] != null && 
            json['results']['channels'].isNotEmpty &&
            json['results']['channels'][0]['alternatives'] != null &&
            json['results']['channels'][0]['alternatives'].isNotEmpty) {
          return json['results']['channels'][0]['alternatives'][0]['transcript'] ?? '';
        }
        // Fallback: join words if available
        if (json['results'] != null && json['results']['words'] != null) {
          final words = json['results']['words'] as List;
          return words.map((w) => w['punctuated_word'] ?? w['word'] ?? '').join(' ').trim();
        }
        return content.trim();
      } catch (e) {
        debugPrint('Error parsing JSON transcript: $e');
        return content.trim();
      }
    }
    
    if (fileName.endsWith('.srt') || fileName.endsWith('.vtt')) {
      // SRT/VTT format - strip timestamps and numbers
      final lines = content.split('\n');
      final textLines = <String>[];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        // Skip empty lines, timestamps, and sequence numbers
        if (line.isEmpty || 
            RegExp(r'^\d+$').hasMatch(line) || // sequence numbers
            RegExp(r'^\d{2}:\d{2}:\d{2},\d{3}').hasMatch(line) || // SRT timestamps
            RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}').hasMatch(line) || // VTT timestamps
            line.startsWith('WEBVTT') || // VTT header
            line.contains('-->')) { // timestamp arrows
          continue;
        }
        textLines.add(line);
      }
      
      return textLines.join(' ').trim();
    }
    
    return content.trim();
  }

  /// Handle transcript file upload
  Future<Map<String, dynamic>> _handleTranscriptUpload(PlatformFile file, Uint8List fileBytes) async {
    try {
      debugPrint('📝 Processing transcript file: ${file.name}');
      
      // Parse transcript text
      final transcriptText = await _parseTranscript(file, fileBytes);
      if (transcriptText.isEmpty) {
        return {
          'success': false,
          'error': 'Empty transcript',
          'message': 'The transcript file appears to be empty'
        };
      }
      
      debugPrint('✅ Transcript parsed successfully (${transcriptText.length} chars)');
      
      // Create a temporary file path for the pipeline service
      final tempPath = '/tmp/transcript_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      // Call pipeline service with transcript
      final pipeline = PipelineService();
      final result = await pipeline.run(
        tempPath,
        providedTranscript: true,
        transcriptText: transcriptText,
        contentType: 'text/plain',
      );
      
      return {
        'success': true,
        'run_id': result['recordingId'],
        'summary_id': result['summaryId'],
        'transcript_text': transcriptText,
        'file_name': file.name,
        'file_size': file.size,
        'is_transcript': true,
      };
    } catch (e) {
      debugPrint('❌ Transcript upload error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to process transcript file'
      };
    }
  }
}