// lib/services/storage_service.dart
import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bucket = 'recordings';

String _two(int n) => n.toString().padLeft(2, '0');

String _pseudoUuid() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  const hex = '0123456789abcdef';
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(hex[(b >> 4) & 0xF]);
    sb.write(hex[b & 0xF]);
  }
  return sb.toString();
}

/// PRD path rule:
/// recordings/{userId}/{yyyy}/{MM}/{dd}/{uuid}.m4a
String buildRecordingPath({String? ext = 'm4a'}) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
  final now = DateTime.now().toUtc();
  final yyyy = now.year.toString();
  final mm = _two(now.month);
  final dd = _two(now.day);
  final id = _pseudoUuid();
  final safeExt = (ext ?? 'm4a').replaceAll('.', '');
  return 'recordings/$userId/$yyyy/$mm/$dd/$id.$safeExt';
}

/// Upload a local audio file to Storage and return the object path.
Future<String> uploadRecordingLocalPath(String localFilePath, {String? contentType}) async {
  final file = File(localFilePath);
  if (!await file.exists()) {
    throw Exception('File not found: $localFilePath');
  }
  final path = buildRecordingPath(ext: _inferExt(localFilePath));
  final bytes = await file.readAsBytes();

  final res = await Supabase.instance.client.storage
      .from(_bucket)
      .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: false,
          contentType: contentType ?? _inferContentType(localFilePath),
        ),
      );

  if (res.isEmpty) {
    // supabase returns the path string on success; if empty, consider this a failure.
    throw Exception('Upload failed');
  }
  return path;
}

/// Create a short-lived signed URL for the given storage object path.
Future<String> signedUrlForRecording(String objectPath, {int expiresInSeconds = 900}) async {
  final signed = await Supabase.instance.client.storage
      .from(_bucket)
      .createSignedUrl(objectPath, expiresInSeconds);

  if (signed.isEmpty) {
    throw Exception('Failed to create signed URL');
  }
  return signed;
}

String _inferExt(String path) {
  final idx = path.lastIndexOf('.');
  if (idx < 0) return 'm4a';
  final ext = path.substring(idx + 1).toLowerCase();
  // keep common audio extensions; default to m4a
  const allowed = {'m4a','mp4','aac','wav','mp3','ogg','webm'};
  return allowed.contains(ext) ? ext : 'm4a';
}

String _inferContentType(String path) {
  final ext = _inferExt(path);
  switch (ext) {
    case 'm4a':
    case 'mp4':
    case 'aac':
      return 'audio/mp4';
    case 'wav':
      return 'audio/wav';
    case 'mp3':
      return 'audio/mpeg';
    case 'ogg':
      return 'audio/ogg';
    case 'webm':
      return 'audio/webm';
    default:
      return 'application/octet-stream';
  }
}
