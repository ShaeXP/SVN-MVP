// lib/services/recording.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingResult {
  final File file;
  final int? durationMs;
  RecordingResult({required this.file, this.durationMs});
}

abstract class RecordingService {
  Future<void> startRecording();
  Future<RecordingResult> stopRecording();
}

/// Real recorder (mobile). Prompts for mic permission when recording starts.
class RealRecordingService implements RecordingService {
  final AudioRecorder _rec =
      AudioRecorder(); // Use AudioRecorder instead of Record
  DateTime? _startedAt;
  String? _path;

  @override
  Future<void> startRecording() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Microphone recording isn\'t supported in this web preview.');
    }

    final ok = await _rec.hasPermission();
    if (!ok) {
      // Some Android/iOS versions won't show a system sheet unless you try to start.
      // We still bail here to keep UX clear.
      throw Exception('Microphone permission was not granted.');
    }

    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/sv_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacHe,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _path!,
    );

    _startedAt = DateTime.now();
  }

  @override
  Future<RecordingResult> stopRecording() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Microphone recording isn\'t supported in this web preview.');
    }

    final path = await _rec.stop();
    final p = path ?? _path;
    if (p == null) {
      throw Exception('No audio captured.');
    }

    final dur = _startedAt == null
        ? null
        : DateTime.now().difference(_startedAt!).inMilliseconds;

    return RecordingResult(file: File(p), durationMs: dur);
  }
}

/// Lightweight mock for previews/tests (does NOT ask permissions)
class MockRecordingService implements RecordingService {
  @override
  Future<void> startRecording() async {}

  @override
  Future<RecordingResult> stopRecording() async {
    final dir = await getTemporaryDirectory();
    final f =
        File('${dir.path}/mock_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await f.writeAsBytes(const <int>[]); // empty file
    return RecordingResult(file: f, durationMs: 1500);
  }
}