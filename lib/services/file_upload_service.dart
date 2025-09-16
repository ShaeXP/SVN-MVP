import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import './recording_backend_service.dart';

class FileUploadService {
  static FileUploadService? _instance;
  static FileUploadService get instance => _instance ??= FileUploadService._();

  FileUploadService._();

  final RecordingBackendService _backendService =
      RecordingBackendService.instance;

  /// Pick and upload audio file with same pipeline as recording
  Future<Map<String, dynamic>> pickAndUploadAudioFile() async {
    try {
      debugPrint('📂 Starting file picker for audio upload...');

      // Step 1: Pick audio file with .webm/.m4a filtering
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webm', 'm4a', 'wav', 'mp3', 'aac'],
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
      if (!fileName.endsWith('.webm') &&
          !fileName.endsWith('.m4a') &&
          !fileName.endsWith('.wav') &&
          !fileName.endsWith('.mp3') &&
          !fileName.endsWith('.aac')) {
        return {
          'success': false,
          'error': 'Invalid file format',
          'message': 'Please select a .webm, .m4a, .wav, .mp3, or .aac file'
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

      // Step 4: Use existing backend service pipeline
      final backendResult = await _backendService.processStopRecording(
        recordingBlob: fileBytes,
        durationMs: estimatedDurationMs,
      );

      if (backendResult['success']) {
        debugPrint('✅ File upload completed successfully');
        return {
          ...backendResult,
          'file_name': file.name,
          'file_size': file.size,
        };
      } else {
        debugPrint('❌ File upload failed: ${backendResult['error']}');
        return backendResult;
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
      ['.webm', '.m4a', '.wav', '.mp3', '.aac'];
}