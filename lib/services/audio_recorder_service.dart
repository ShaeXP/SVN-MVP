import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioRecorderService {
  AudioRecorderService() {
    _rec = FlutterSoundRecorder();
  }

  FlutterSoundRecorder? _rec;
  bool _sessionOpen = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentPath;

  bool get isRecording => _isRecording;
  FlutterSoundRecorder? get recorder => _rec;

  Future<void> _ensureSession() async {
    if (_sessionOpen) return;
    if (_rec == null) {
      throw StateError('Recorder is not initialized');
    }
    
    try {
      debugPrint('[REC_SVC] Opening recorder session...');
      await _rec!.openRecorder();
      _sessionOpen = true;
      debugPrint('[REC_SVC] Recorder session opened successfully');
    } on PlatformException catch (e, st) {
      debugPrint('[REC_SVC][ERR] PlatformException in _ensureSession: $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _sessionOpen = false;
      rethrow;
    } catch (e, st) {
      debugPrint('[REC_SVC][ERR] Unexpected error in _ensureSession: $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _sessionOpen = false;
      rethrow;
    }
  }

  Future<void> start() async {
    debugPrint('[REC_SVC] start() requested, isRecording=$_isRecording');
    
    if (_isRecording) {
      debugPrint('[REC_SVC] start() ignored: already recording');
      return;
    }
    
    if (_rec == null) {
      debugPrint('[REC_SVC][ERR] start() failed: recorder not initialized');
      throw StateError('Recorder is not initialized');
    }
    
    try {
      await _ensureSession();

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentPath = path;

      debugPrint('[REC_SVC] calling plugin.startRecorder with path=$path');

      // Speech-optimized settings: mono, compressed AAC, 16kHz, ~64kbps
      // These settings reduce file size while maintaining good speech quality
      await _rec!.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        bitRate: 64000,      // Reduced from 128kbps to 64kbps for speech
        sampleRate: 16000,   // Reduced from 44.1kHz to 16kHz (sufficient for speech)
        numChannels: 1,      // Mono (already optimal for speech)
      );
      
      _isRecording = true;
      _isPaused = false;
      debugPrint('[REC_SVC] start() OK, path=$path');
    } on PlatformException catch (e, st) {
      debugPrint('[REC_SVC][ERR] PlatformException in start(): $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _isRecording = false;
      _currentPath = null;
      rethrow; // let controller handle user-facing error
    } catch (e, st) {
      debugPrint('[REC_SVC][ERR] Unexpected error in start(): $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _isRecording = false;
      _currentPath = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    if (!_isRecording || _isPaused) return;
    await _rec!.pauseRecorder();
    _isPaused = true;
  }

  Future<void> resume() async {
    if (!_isRecording || !_isPaused) return;
    await _rec!.resumeRecorder();
    _isPaused = false;
  }

  Future<String> stop() async {
    debugPrint('[REC_SVC] stop() requested, isRecording=$_isRecording');

    if (!_isRecording) {
      debugPrint('[REC_SVC] stop() ignored: not recording');
      throw StateError('Not recording');
    }
    
    if (_rec == null) {
      debugPrint('[REC_SVC][ERR] stop() failed: recorder not initialized');
      throw StateError('Recorder is not initialized');
    }

    try {
      final resultPath = await _rec!.stopRecorder();
      _isRecording = false;
      _isPaused = false;
      debugPrint('[REC_SVC] stop() OK, resultPath=$resultPath, currentPath=$_currentPath');
      return resultPath ?? _currentPath ?? '';
    } on PlatformException catch (e, st) {
      debugPrint('[REC_SVC][ERR] PlatformException in stop(): $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _isRecording = false;
      _currentPath = null;
      rethrow;
    } catch (e, st) {
      debugPrint('[REC_SVC][ERR] Unexpected error in stop(): $e');
      debugPrint('[REC_SVC][ERR] Stack: $st');
      _isRecording = false;
      _currentPath = null;
      rethrow;
    } finally {
      _currentPath = null;
    }
  }

  Future<void> dispose() async {
    debugPrint('[REC_SVC] dispose() called');
    try {
      if (_isRecording) {
        try {
          await _rec!.stopRecorder();
        } catch (e) {
          debugPrint('[REC_SVC] Error stopping recorder during dispose: $e');
        }
      }
      if (_sessionOpen && _rec != null) {
        try {
          await _rec!.closeRecorder();
        } catch (e) {
          debugPrint('[REC_SVC] Error closing recorder during dispose: $e');
        }
        _sessionOpen = false;
      }
      _isRecording = false;
      _isPaused = false;
      _currentPath = null;
      debugPrint('[REC_SVC] dispose() completed');
    } catch (e) {
      debugPrint('[REC_SVC][ERR] Error in dispose(): $e');
    }
  }
}