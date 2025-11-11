// lib/services/upload_models.dart
import 'dart:typed_data';
import 'dart:io';

/// Strong types for upload functionality
class SignedUpload {
  final String method;           // 'PUT' | 'POST'
  final String url;              // pre-signed url
  final Map<String, String>? fields; // for POST form, else null
  final String recordingId;
  final String storagePath;
  final String contentType;      // echoed from signer

  SignedUpload({
    required this.method,
    required this.url,
    this.fields,
    required this.recordingId,
    required this.storagePath,
    required this.contentType,
  });

  factory SignedUpload.fromJson(Map<String, dynamic> json) {
    // Defensive parsing with null checks
    final method = json['method'] as String?;
    if (method == null || method.isEmpty) {
      throw UploadError('Signer error: missing method');
    }

    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw UploadError('Signer error: missing URL');
    }

    final recordingId = json['recordingId'] as String?;
    if (recordingId == null || recordingId.isEmpty) {
      throw UploadError('Signer error: missing recordingId');
    }

    final storagePath = json['storagePath'] as String?;
    if (storagePath == null || storagePath.isEmpty) {
      throw UploadError('Signer error: missing storagePath');
    }

    final contentType = json['contentType'] as String?;
    if (contentType == null || contentType.isEmpty) {
      throw UploadError('Signer error: missing contentType');
    }

    // Parse fields if present (for POST form uploads)
    Map<String, String>? fields;
    final fieldsJson = json['fields'] as Map<String, dynamic>?;
    if (fieldsJson != null) {
      fields = fieldsJson.map((key, value) => MapEntry(key, value.toString()));
    }

    return SignedUpload(
      method: method,
      url: url,
      fields: fields,
      recordingId: recordingId,
      storagePath: storagePath,
      contentType: contentType,
    );
  }
}

/// Upload error with clear message
class UploadError implements Exception {
  final String message;
  UploadError(this.message);
  
  @override
  String toString() => message;
}

/// File picker result with null safety
class PickedFile {
  final String filename;
  final Uint8List bytes;
  final String contentType;

  PickedFile({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  static Future<PickedFile?> fromFilePicker(dynamic file) async {
    try {
      // Get filename with fallback
      final filename = file.name ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Get bytes with multiple fallbacks
      Uint8List? bytes;
      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        // Try to read from file path
        final fileObj = File(file.path!);
        if (await fileObj.exists()) {
          bytes = await fileObj.readAsBytes();
        }
      }
      
      if (bytes == null) {
        throw UploadError('Could not read selected file');
      }

      // Infer content type
      final contentType = _inferMimeType(filename);

      return PickedFile(
        filename: filename,
        bytes: bytes,
        contentType: contentType,
      );
    } catch (e) {
      throw UploadError('File selection failed: $e');
    }
  }

  static String _inferMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'm4a':
      case 'mp4':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      default:
        return 'application/octet-stream';
    }
  }
}
