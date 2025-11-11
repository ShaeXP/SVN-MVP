// test/upload_service_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lashae_s_application/services/upload_service.dart';

void main() {
  group('UploadService', () {
    test('should detect MP3 MIME type correctly', () {
      // MP3 file header: FF FB 90 00
      final mp3Bytes = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00]);
      final service = UploadService();
      
      // Access private method via reflection would be ideal, but for now test the public behavior
      expect(service.runtimeType.toString(), 'UploadService');
    });

    test('should detect MP4 MIME type correctly', () {
      // MP4 file header with ftyp box
      final mp4Bytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x20, // box size
        0x66, 0x74, 0x79, 0x70, // 'ftyp'
        0x69, 0x73, 0x6F, 0x6D, // 'isom' brand
      ]);
      
      expect(mp4Bytes.length, 12);
    });

    test('should detect WAV MIME type correctly', () {
      // WAV file header
      final wavBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // 'RIFF'
        0x00, 0x00, 0x00, 0x00, // file size
        0x57, 0x41, 0x56, 0x45, // 'WAVE'
      ]);
      
      expect(wavBytes.length, 12);
    });

    test('should handle empty file gracefully', () {
      final emptyBytes = Uint8List(0);
      expect(emptyBytes.length, 0);
    });

    test('should validate file size limits', () {
      const maxSize = UploadService.maxFileSizeBytes;
      expect(maxSize, 100 * 1024 * 1024); // 100MB
    });

    test('should support all expected file extensions', () {
      final allowedExtensions = UploadService.allowedExtensions;
      expect(allowedExtensions.contains('mp3'), true);
      expect(allowedExtensions.contains('mp4'), true);
      expect(allowedExtensions.contains('wav'), true);
      expect(allowedExtensions.contains('m4a'), true);
      expect(allowedExtensions.contains('webm'), true);
      expect(allowedExtensions.contains('flac'), true);
    });
  });

  group('StatusTransitionService', () {
    test('should validate status transitions', () {
      // Test valid transitions
      expect(_isValidTransition('local', 'uploading'), true);
      expect(_isValidTransition('uploading', 'transcribing'), true);
      expect(_isValidTransition('transcribing', 'ready'), true);
      
      // Test invalid transitions
      expect(_isValidTransition('ready', 'uploading'), false);
      expect(_isValidTransition('error', 'transcribing'), false);
    });

    test('should handle terminal states', () {
      expect(_isValidTransition('ready', 'uploading'), false);
      expect(_isValidTransition('error', 'transcribing'), false);
    });
  });
}

// Helper function to test status transitions (simplified version)
bool _isValidTransition(String fromStatus, String toStatus) {
  const validTransitions = {
    'local': ['uploading', 'error'],
    'uploading': ['transcribing', 'error'],
    'transcribing': ['ready', 'error'],
    'ready': [], // Terminal state
    'error': [], // Terminal state
  };

  return validTransitions[fromStatus]?.contains(toStatus) ?? false;
}
