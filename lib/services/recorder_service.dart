import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecorderResult {
  final File file;
  final Duration duration;
  final String mime; // 'audio/wav' on Windows, 'audio/m4a' elsewhere
  RecorderResult({required this.file, required this.duration, required this.mime});
}

class RecorderService {
  final _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> isAvailable() async => await _recorder.hasPermission();

  Future<File> _tempFilePath({required bool useWav}) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = useWav ? 'wav' : 'm4a';
    return File('${dir.path}/svn_$ts.$ext');
  }

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }
    final isWindows = Platform.isWindows;
    final outFile = await _tempFilePath(useWav: isWindows);
    _startedAt = DateTime.now();

    final recordConfig = isWindows
        ? const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100)
        : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);

    await _recorder.start(recordConfig, path: outFile.path);
  }

  Future<RecorderResult> stop() async {
    final path = await _recorder.stop();
    if (path == null) throw Exception('No recording path returned');
    final f = File(path);
    final started = _startedAt ?? DateTime.now();
    final dur = DateTime.now().difference(started);
    final isWav = path.toLowerCase().endsWith('.wav');
    return RecorderResult(file: f, duration: dur, mime: isWav ? 'audio/wav' : 'audio/m4a');
  }

  Future<void> dispose() async { try { await _recorder.dispose(); } catch (_) {} }
}
