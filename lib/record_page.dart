import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:lashae_s_application/app/routes/app_pages.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  String? _filePath;
  bool _isRecording = false;
  String _status = 'Idle';

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<String> _makePath({required String ext}) async {
    final dir = await getTemporaryDirectory();
    final name = 'note_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = p.join(dir.path, name);
    return path;
  }

  Future<bool> _ensureMicPermission() async {
    if (kIsWeb) {
      setState(() => _status =
          'Web recording is disabled in this build. Use Windows desktop for now.');
      return false;
    }

    var state = await Permission.microphone.status;
    if (state.isGranted) return true;

    state = await Permission.microphone.request();
    if (state.isGranted) return true;

    setState(() => _status = 'Microphone permission not granted.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Open OS microphone settings to allow access.'),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: () async {
            if (defaultTargetPlatform == TargetPlatform.windows) {
              await launchUrl(
                Uri.parse('ms-settings:privacy-microphone'),
                mode: LaunchMode.externalApplication,
              );
            } else {
              await openAppSettings();
            }
          },
        ),
      ),
    );
    return false;
  }

  Future<void> _start() async {
    if (!await _ensureMicPermission()) return;

    // Build a config WITHOUT nullable fields.
    final RecordConfig config = _isDesktop
        ? const RecordConfig(
            encoder: AudioEncoder.wav, // safest on desktop
            sampleRate: 44100,
            numChannels: 1,
          )
        : const RecordConfig(
            encoder: AudioEncoder.aacHe, // good on Android/iOS
            sampleRate: 44100,
            bitRate: 128000, // non-null
            numChannels: 1,
          );

    // Choose extension per platform
    final String ext = _isDesktop ? 'wav' : 'm4a';
    final String path = await _makePath(ext: ext);

    try {
      await _recorder.start(config, path: path);
      setState(() {
        _filePath = path;
        _isRecording = true;
        _status = 'Recordingâ€¦\n$path';
      });
    } catch (e) {
      setState(() => _status = 'Start error: $e');
    }
  }

  Future<void> _stop() async {
    try {
      final result = await _recorder.stop();
      if (result != null) _filePath = result;

      // Verify file exists and has bytes
      if (_filePath != null && File(_filePath!).existsSync()) {
        final bytes = await File(_filePath!).length();
        setState(() {
          _isRecording = false;
          _status = 'Stopped. File OK (${bytes} bytes)\n$_filePath';
        });
      } else {
        setState(() {
          _isRecording = false;
          _status = 'Stopped, but file missing.\nPath was: $_filePath';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _status = 'Stop error: $e';
      });
    }
  }

  Future<void> _play() async {
    try {
      if (_filePath == null || !File(_filePath!).existsSync()) {
        setState(() => _status = 'File missing â€” nothing to play');
        return;
      }
      await _player.setFilePath(_filePath!);
      await _player.play();
      setState(() => _status = 'Playingâ€¦');
    } catch (e) {
      setState(() => _status = 'Playback error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isDesktop ? 'Record Test (Desktop)' : 'Record Test')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRecording ? _stop : _start,
              child: Text(_isRecording ? 'Stop' : 'Start Recording'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isRecording ? null : _play,
              child: const Text('Play Last Recording'),
            ),
            const SizedBox(height: 12),
            if (_filePath != null)
              Text(_filePath!, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
