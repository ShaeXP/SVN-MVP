import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioRecorderService {
  AudioRecorderService() {
    _rec = FlutterSoundRecorder();
  }

  FlutterSoundRecorder? _rec;
  bool _sessionOpen = false;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> _ensureSession() async {
    if (_sessionOpen) return;
    await _rec!.openRecorder();
    _sessionOpen = true;
  }

  Future<void> start() async {
    if (_isRecording) return;
    await _ensureSession();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _rec!.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );
    _isRecording = true;
  }

  Future<String> stop() async {
    if (!_isRecording) {
      throw StateError('Not recording');
    }
    final resultPath = await _rec!.stopRecorder();
    _isRecording = false;
    return resultPath!;
  }

  Future<void> dispose() async {
    try { await _rec!.stopRecorder(); } catch (_) {}
    if (_sessionOpen) {
      await _rec!.closeRecorder();
      _sessionOpen = false;
    }
  }
}