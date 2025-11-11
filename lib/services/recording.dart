// lib/services/recording.dart
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec; // â† alias to avoid name clashes

class RecordingResult {
  final File file;
  final int? durationMs;
  RecordingResult({required this.file, this.durationMs});
}

abstract class RecordingService {
  Future<void> startRecording();
  Future<RecordingResult> stopRecording();
  
  /// Check if microphone permission is granted
  Future<bool> hasMicPermission();
  
  /// Check if any input device is available
  Future<bool> hasAnyInputDevice();
  
  /// Safe entry point to check if recording can proceed
  Future<bool> canRecordNow();
}

/// Real recorder (device/emulator). Uses record v5 AudioRecorder API.
class RealRecordingService implements RecordingService {
  final rec.AudioRecorder _rec = rec.AudioRecorder();
  DateTime? _startedAt;
  String? _path;

  @override
  Future<void> startRecording() async {
    // Permission gate
    final ok = await _rec.hasPermission();
    if (!ok) {
      throw Exception(
        'Microphone permission not granted (or blocked by host). '
        'On Android Emulator: Moreâ€¦ â€º Microphone must be enabled.',
      );
    }

    // Optional: ensure encoder support; fallback if needed
    final supportsHe = await _rec.isEncoderSupported(rec.AudioEncoder.aacHe);
    final encoder =
        supportsHe ? rec.AudioEncoder.aacHe : rec.AudioEncoder.aacLc;

    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/sv_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final cfg = rec.RecordConfig(
      encoder: encoder,
      bitRate: 128000,
      sampleRate: 44100,
    );

    await _rec.start(cfg, path: _path!);
    _startedAt = DateTime.now();
  }

  @override
  Future<RecordingResult> stopRecording() async {
    final path = await _rec.stop();
    final p = path ?? _path;
    if (p == null) {
      throw Exception(
          'No audio captured. Try again after granting mic access.');
    }

    final dur = _startedAt == null
        ? null
        : DateTime.now().difference(_startedAt!).inMilliseconds;

    return RecordingResult(file: File(p), durationMs: dur);
  }

  @override
  Future<bool> hasMicPermission() async => await _rec.hasPermission();

  @override
  Future<bool> hasAnyInputDevice() async {
    try {
      final inputs = await _rec.listInputDevices();
      return inputs != null && inputs.isNotEmpty;
    } catch (e) {
      // If listing devices fails, assume no devices available
      return false;
    }
  }

  @override
  Future<bool> canRecordNow() async {
    return await hasMicPermission() && await hasAnyInputDevice();
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

  @override
  Future<bool> hasMicPermission() async => true; // Mock always has permission

  @override
  Future<bool> hasAnyInputDevice() async => true; // Mock always has devices

  @override
  Future<bool> canRecordNow() async => true; // Mock can always record
}
