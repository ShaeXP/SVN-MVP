import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pipeline.dart';

class UploadService {
  final supa = Supabase.instance.client;
  final _pipeline = Pipeline();

  static const allowedExtensions = [
    'm4a','mp3','wav','aac','mp4','caf','ogg','webm','mov','avi','mkv','flac','wma'
  ];
  
  // Maximum file size for mobile uploads (100MB)
  static const maxFileSizeBytes = 100 * 1024 * 1024;

  Future<_PickedFile?> pickAudioOrVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false, // use path to avoid big in-memory blobs
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.path == null) return null;
    final ext = (f.extension ?? '').toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw 'Unsupported file type .$ext';
    }
    
    final file = File(f.path!);
    final fileSize = await file.length();
    
    if (fileSize > maxFileSizeBytes) {
      throw 'File too large for mobile upload. Try desktop upload. (Max: ${(maxFileSizeBytes / 1024 / 1024).toStringAsFixed(0)}MB)';
    }
    
    return _PickedFile(file, ext, fileSize);
  }
  
  // Backward compatibility
  Future<_PickedFile?> pickAudio() async {
    return pickAudioOrVideo();
  }

  Future<String> uploadAudio(File file, String ext) async {
    final user = supa.auth.currentUser;
    if (user == null) {
      throw 'You must be signed in to upload.';
    }

    // Read file bytes for MIME sniffing
    final bytes = await file.readAsBytes();
    
    // Validate MIME type by sniffing file headers
    final detectedMime = _detectMimeType(bytes);
    final expectedMime = _mimeFromExt(ext);
    
    // Log MIME detection for debugging
    print('[UPLOAD] File: $ext, Expected: $expectedMime, Detected: $detectedMime');
    
    // Use detected MIME type for upload
    final contentType = detectedMime.isNotEmpty ? detectedMime : expectedMime;

    // Create object key (without bucket prefix)
    final now = DateTime.now();
    final yyyy = DateFormat('yyyy').format(now);
    final mm = DateFormat('MM').format(now);
    final dd = DateFormat('dd').format(now);
    final unique = '${now.millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
    final objectKey = '${user.id}/$yyyy/$mm/$dd/$unique.$ext';
    
    // Storage path for DB (with bucket prefix)
    final storagePath = 'recordings/$objectKey';

    // Upload audio bytes using object key (no bucket prefix)
    await _pipeline.uploadAudioBytes(
      path: objectKey,  // Object key without bucket prefix
      bytes: bytes,
      contentType: contentType,
    );

    return storagePath; // Return storage path with bucket prefix for DB
  }

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'm4a': return 'audio/m4a';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'aac': return 'audio/aac';
      case 'mp4': return 'video/mp4';
      case 'caf': return 'application/x-caf';
      case 'ogg': return 'audio/ogg';
      case 'webm': return 'video/webm';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'mkv': return 'video/x-matroska';
      case 'flac': return 'audio/flac';
      case 'wma': return 'audio/x-ms-wma';
      default: return 'application/octet-stream';
    }
  }

  /// Detect MIME type by examining file headers
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) return '';
    
    // Check common audio/video file signatures
    final header = bytes.sublist(0, min(12, bytes.length));
    
    // MP3 files
    if (header.length >= 3 && 
        header[0] == 0xFF && (header[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }
    
    // MP4/M4A files (ftyp box)
    if (header.length >= 8 && 
        header[4] == 0x66 && header[5] == 0x74 && 
        header[6] == 0x79 && header[7] == 0x70) {
      // Check if it's audio or video
      if (header.length >= 12) {
        final brand = String.fromCharCodes(header.sublist(8, 12));
        if (brand == 'M4A ') return 'audio/m4a';
        if (brand == 'isom' || brand == 'mp41' || brand == 'mp42') return 'video/mp4';
      }
      return 'audio/m4a'; // Default for M4A
    }
    
    // WAV files
    if (header.length >= 12 && 
        header[0] == 0x52 && header[1] == 0x49 && 
        header[2] == 0x46 && header[3] == 0x46 &&
        header[8] == 0x57 && header[9] == 0x41 && 
        header[10] == 0x56 && header[11] == 0x45) {
      return 'audio/wav';
    }
    
    // OGG files
    if (header.length >= 4 && 
        header[0] == 0x4F && header[1] == 0x67 && 
        header[2] == 0x67 && header[3] == 0x53) {
      return 'audio/ogg';
    }
    
    // FLAC files
    if (header.length >= 4 && 
        header[0] == 0x66 && header[1] == 0x4C && 
        header[2] == 0x61 && header[3] == 0x43) {
      return 'audio/flac';
    }
    
    // WebM files
    if (header.length >= 4 && 
        header[0] == 0x1A && header[1] == 0x45 && 
        header[2] == 0xDF && header[3] == 0xA3) {
      return 'video/webm';
    }
    
    // AVI files
    if (header.length >= 12 && 
        header[0] == 0x52 && header[1] == 0x49 && 
        header[2] == 0x46 && header[3] == 0x46 &&
        header[8] == 0x41 && header[9] == 0x56 && 
        header[10] == 0x49 && header[11] == 0x20) {
      return 'video/x-msvideo';
    }
    
    return ''; // Unknown format
  }
}

class _PickedFile {
  final File file;
  final String ext;
  final int sizeBytes;
  _PickedFile(this.file, this.ext, this.sizeBytes);
}
