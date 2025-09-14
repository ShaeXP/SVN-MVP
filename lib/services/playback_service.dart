import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bootstrap_supabase.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();

  /// Load and play a **local file**.
  Future<void> playLocalFile(String path) async {
    // On Windows, setFilePath works directly with absolute paths.
    await _player.setFilePath(path);
    await _player.play();
  }

  /// Load and play a file by **Supabase storage path** (e.g., user/<uid>/<run_id>.wav).
  /// This creates a short-lived signed URL and streams it.
  Future<void> playFromSupabase(String storagePath, {Duration? expiresIn}) async {
    final storage = Supa.client.storage.from('audio');
    final signed = await storage.createSignedUrl(storagePath, (expiresIn ?? const Duration(minutes: 5)).inSeconds);
    // just_audio expects a URL
    await _player.setUrl(signed);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    try { await _player.dispose(); } catch (_) {}
  }
}
