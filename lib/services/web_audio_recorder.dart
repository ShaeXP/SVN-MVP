import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class WebAudioRecorder {
  static WebAudioRecorder? _instance;
  static WebAudioRecorder get instance => _instance ??= WebAudioRecorder._();

  WebAudioRecorder._();

  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _mediaStream;
  List<html.Blob> _recordedChunks = [];
  bool _isRecording = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pauseStartTime;
  int _totalPausedDuration = 0;

  // Stream controllers for recording events
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<List<double>> _waveformController = StreamController<List<double>>.broadcast();
  final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();

  // Getters for streams
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<List<double>> get waveformStream => _waveformController.stream;
  Stream<RecordingState> get stateStream => _stateController.stream;

  // Timer for duration updates
  Timer? _durationTimer;
  dynamic _audioContext;
  dynamic _analyser;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;

  /// Initialize and start recording
  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        debugPrint('⚠️ Recording already in progress');
        return false;
      }

      // Request microphone permission
      _mediaStream = await html.window.navigator.getUserMedia(audio: true);
      if (_mediaStream == null) {
        throw Exception('Failed to get audio stream');
      }

      // Set up audio analysis for waveform
      await _setupAudioAnalysis(_mediaStream!);

      // Create MediaRecorder
      _mediaRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': _getSupportedMimeType(),
      });

      _recordedChunks.clear();
      _totalPausedDuration = 0;
      _startTime = DateTime.now();

      // Set up event handlers using addEventListener instead of on* getters
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final data = js_util.getProperty(event, 'data');
        if (js_util.getProperty(data, 'size') > 0) {
          _recordedChunks.add(data);
        }
      });

      _mediaRecorder!.addEventListener('start', (_) {
        debugPrint('🎤 Recording started');
        _isRecording = true;
        _isPaused = false;
        _stateController.add(RecordingState.recording);
        _startDurationTimer();
      });

      _mediaRecorder!.addEventListener('stop', (_) {
        debugPrint('⏹️ Recording stopped');
        _isRecording = false;
        _isPaused = false;
        _stateController.add(RecordingState.stopped);
        _stopDurationTimer();
      });

      _mediaRecorder!.addEventListener('pause', (_) {
        debugPrint('⏸️ Recording paused');
        _isPaused = true;
        _pauseStartTime = DateTime.now();
        _stateController.add(RecordingState.paused);
      });

      _mediaRecorder!.addEventListener('resume', (_) {
        debugPrint('▶️ Recording resumed');
        _isPaused = false;
        if (_pauseStartTime != null) {
          _totalPausedDuration += DateTime.now().difference(_pauseStartTime!).inMilliseconds;
          _pauseStartTime = null;
        }
        _stateController.add(RecordingState.recording);
      });

      // Start recording
      _mediaRecorder!.start();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      await _cleanup();
      return false;
    }
  }

  /// Pause recording
  bool pauseRecording() {
    if (!_isRecording || _isPaused || _mediaRecorder == null) {
      return false;
    }

    try {
      _mediaRecorder!.pause();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to pause recording: $e');
      return false;
    }
  }

  /// Resume recording
  bool resumeRecording() {
    if (!_isRecording || !_isPaused || _mediaRecorder == null) {
      return false;
    }

    try {
      _mediaRecorder!.resume();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to resume recording: $e');
      return false;
    }
  }

  /// Stop recording and return the recorded audio blob
  Future<Uint8List?> stopRecording() async {
    if (!_isRecording || _mediaRecorder == null) {
      debugPrint('⚠️ No recording in progress');
      return null;
    }

    try {
      // Complete the recording
      final completer = Completer<Uint8List?>();
      
      _mediaRecorder!.addEventListener('stop', (_) async {
        try {
          if (_recordedChunks.isNotEmpty) {
            // Create final blob from recorded chunks
            final blob = html.Blob(_recordedChunks, _getSupportedMimeType());
            
            // Convert blob to Uint8List
            final reader = html.FileReader();
            reader.readAsArrayBuffer(blob);
            reader.onLoad.listen((_) {
              final arrayBuffer = reader.result as ByteBuffer;
              final uint8List = Uint8List.view(arrayBuffer);
              completer.complete(uint8List);
            });
            reader.onError.listen((_) {
              debugPrint('❌ Failed to convert blob to Uint8List');
              completer.complete(null);
            });
          } else {
            completer.complete(null);
          }
        } catch (e) {
          debugPrint('❌ Error processing recorded data: $e');
          completer.complete(null);
        }
      });

      _mediaRecorder!.stop();
      final result = await completer.future;
      
      await _cleanup();
      return result;
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      await _cleanup();
      return null;
    }
  }

  /// Get current recording duration
  Duration getCurrentDuration() {
    if (_startTime == null || !_isRecording) {
      return Duration.zero;
    }

    final now = DateTime.now();
    final totalDuration = now.difference(_startTime!).inMilliseconds;
    
    // Subtract paused time
    int pausedTime = _totalPausedDuration;
    if (_isPaused && _pauseStartTime != null) {
      pausedTime += now.difference(_pauseStartTime!).inMilliseconds;
    }
    
    return Duration(milliseconds: math.max(0, totalDuration - pausedTime));
  }

  /// Set up audio analysis for waveform visualization
  Future<void> _setupAudioAnalysis(html.MediaStream stream) async {
    try {
      _audioContext = js_util.callConstructor(js.context['AudioContext'], []);
      final source = js_util.callMethod(_audioContext, 'createMediaStreamSource', [stream]);
      _analyser = js_util.callMethod(_audioContext, 'createAnalyser', []);
      
      js_util.setProperty(_analyser, 'fftSize', 256);
      js_util.callMethod(source, 'connect', [_analyser]);

      // Start waveform analysis
      _startWaveformAnalysis();
    } catch (e) {
      debugPrint('⚠️ Failed to set up audio analysis: $e');
      // Continue without waveform - recording will still work
    }
  }

  /// Start waveform data analysis
  void _startWaveformAnalysis() {
    if (_analyser == null) return;

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording || _isPaused) {
        if (!_isRecording) timer.cancel();
        return;
      }

      try {
        final frequencyBinCount = js_util.getProperty(_analyser, 'frequencyBinCount');
        final dataArray = Float32List(frequencyBinCount);
        js_util.callMethod(_analyser, 'getFloatFrequencyData', [dataArray]);
        
        // Convert to simple amplitude values for waveform visualization
        final waveformData = dataArray.take(32).map((value) {
          return math.max<double>(0.0, math.min<double>(1.0, (value.toDouble() + 100) / 100));
        }).toList();
        
        _waveformController.add(waveformData);
      } catch (e) {
        // Silently continue - waveform is optional
      }
    });
  }

  /// Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isRecording) {
        _durationController.add(getCurrentDuration());
      }
    });
  }

  /// Stop duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Get supported MIME type for MediaRecorder
  String _getSupportedMimeType() {
    // Check for WebM support first (preferred)
    if (html.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
      return 'audio/webm;codecs=opus';
    } else if (html.MediaRecorder.isTypeSupported('audio/webm')) {
      return 'audio/webm';
    } else if (html.MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) {
      return 'audio/ogg;codecs=opus';
    } else if (html.MediaRecorder.isTypeSupported('audio/mp4')) {
      return 'audio/mp4';
    } else {
      // Fallback to basic audio/webm
      return 'audio/webm';
    }
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    try {
      _stopDurationTimer();
      
      _mediaStream?.getTracks().forEach((track) {
        track.stop();
      });
      _mediaStream = null;
      
      if (_audioContext != null) {
        try {
          js_util.callMethod(_audioContext, 'close', []);
        } catch (e) {
          // Ignore close errors
        }
      }
      _audioContext = null;
      _analyser = null;
      
      _mediaRecorder = null;
      _recordedChunks.clear();
      _isRecording = false;
      _isPaused = false;
      _startTime = null;
      _pauseStartTime = null;
      _totalPausedDuration = 0;
    } catch (e) {
      debugPrint('⚠️ Error during cleanup: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanup();
    _durationController.close();
    _waveformController.close();
    _stateController.close();
  }
}

enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}