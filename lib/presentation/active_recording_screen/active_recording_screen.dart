// lib/presentation/active_recording_screen/active_recording_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/app_export.dart';
import '../../services/pipeline.dart';
import '../../services/recording.dart';
import '../../services/supabase_service.dart';
import 'package:flutter/foundation.dart';

// Use real mic on mobile, mock on web
final RecordingService recordingService = RealRecordingService();

class ActiveRecordingScreen extends StatefulWidget {
  const ActiveRecordingScreen({super.key});

  @override
  State<ActiveRecordingScreen> createState() => _ActiveRecordingScreenState();
}

class _ActiveRecordingScreenState extends State<ActiveRecordingScreen> {
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  bool _isRecording = false;
  bool _isSaving = false;

  /// Returned by your RecordingService (XFile/File/Uint8List/whatever)
  dynamic _file;

  /// Milliseconds captured (fallbacks to timer if service doesn’t return)
  int _durationMs = 0;

  final _pipeline = Pipeline();
  final RecordingService recordingService = RealRecordingService();

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────

  void _resetTimer() {
    _ticker?.cancel();
    _elapsed = Duration.zero;
    setState(() {});
  }

  void _startTimer() {
    _ticker?.cancel();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Recording lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _start() async {
    if (_isRecording) return;
    try {
      await recordingService.startRecording(); // should request mic if needed
      setState(() {
        _isRecording = true;
        _file = null;
        _durationMs = 0;
      });
      _startTimer();
    } catch (e) {
      _snack('Microphone unavailable. Enable permission in Settings.\n$e');
    }
  }

  Future<void> _stop() async {
    if (!_isRecording) return;
    try {
      final res = await recordingService.stopRecording();
      _ticker?.cancel();

      setState(() {
        _isRecording = false;
        _file = res.file; // may be null if nothing captured
        _durationMs = res.durationMs ?? _elapsed.inMilliseconds;
      });

      _showReviewSheet();
    } catch (e) {
      _snack('Failed to stop: $e');
    }
  }

  void _onRedo() {
    Navigator.pop(context); // close sheet
    _resetTimer();
    setState(() {
      _isRecording = false;
      _file = null;
      _durationMs = 0;
    });
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    // Basic guards — these were the source of “tap Save, nothing happens”
    if (_file == null) {
      _snack('No audio to save. Try recording again.');
      return;
    }
    if (_durationMs <= 0) {
      _snack('Recording too short to save.');
      return;
    }

    // Auth guard (avoid currentUser! crash)
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _snack('Please sign in to save recordings.');
      return;
    }

    setState(() => _isSaving = true);

    try {
    // 1) create run
    final runId = await _pipeline.initRun();

    // 2) choose extension + storage path
    final ext = _guessExtension(_file); // .m4a/.mp3/.wav/.webm
    final storagePath = 'user/${user.id}/$runId$ext';

    // 3) read bytes + upload to Storage
    final bytes = await _readBytes(_file);
    final contentType = _contentTypeForExtension(ext);
    final audioRef = await _pipeline.uploadAudioBytes(
      path: storagePath,
      bytes: bytes,
      contentType: contentType,
      upsert: true,
      // set to false if your bucket is private and you want to store the path
      storePublicUrl: true,
    );

    // 4) update DB row with audio reference + duration
    await _pipeline.insertRecording(
      runId: runId,
      storagePathOrUrl: audioRef,
      durationMs: _durationMs,
    );

    // 5) start ASR
    await _pipeline.startAsr(runId, audioRef);

    // 6) go to summary
    if (mounted) {
      Navigator.pop(context); // close sheet
      Get.offAllNamed(
        AppRoutes.recordingSummaryScreen,
        arguments: {'run_id': runId},
      );
    }
  } catch (e) {
    _snack(e.toString().replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
  // ─────────────────────────────────────────────────────────────────────────────
  // Upload helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Future<Uint8List> _readBytes(dynamic file) async {
    // Handles File, XFile, Uint8List, List<int>, and objects with readAsBytes()
    try {
      final dynamic dyn = file;
      final res = await dyn.readAsBytes(); // XFile/File duck-typed
      if (res is Uint8List) return res;
      if (res is List<int>) return Uint8List.fromList(res);
    } catch (_) {
      // fallthrough
    }
    if (file is Uint8List) return file;
    if (file is List<int>) return Uint8List.fromList(file);
    if (file is File) return await file.readAsBytes();
    if (file is String) return await File(file).readAsBytes();
    throw Exception('Unsupported file object for upload.');
  }

  String _guessExtension(dynamic file) {
    String path = '';
    try {
      path = (file as dynamic).path as String;
    } catch (_) {}
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a')) return '.m4a';
    if (lower.endsWith('.aac')) return '.aac';
    if (lower.endsWith('.wav')) return '.wav';
    if (lower.endsWith('.mp3')) return '.mp3';
    if (lower.endsWith('.webm')) return '.webm';
    return '.webm';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.wav':
        return 'audio/wav';
      case '.mp3':
        return 'audio/mpeg';
      case '.webm':
      default:
        return 'audio/webm';
    }
  }

  Future<void> _uploadBytesPut(
    String signedUrl,
    Uint8List bytes,
    String contentType,
  ) async {
    final response = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────

  void _showReviewSheet() {
    if (_file == null || _durationMs <= 0) {
      _snack('No recording data');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final canSave = !_isSaving && _file != null && _durationMs > 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Stop recording?',
                  style: TextStyleHelper.instance.title18MediumInter),
              const SizedBox(height: 8),
              Text(_fmt(Duration(milliseconds: _durationMs))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSave ? _onSave : null,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onRedo,
                  child: const Text('Redo'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorder')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                _fmt(_elapsed),
                style: TextStyleHelper.instance.display36BoldQuattrocento,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: appTheme.blue_200_01.withAlpha(51),
                    ),
                  ),
                ),
              ), // waveform placeholder
              const SizedBox(height: 24),

              // Controls
              if (_isRecording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause is optional unless your RecordingService supports it
                    OutlinedButton(
                      onPressed: null, // TODO: wire if your service exposes pause()
                      child: const Icon(Icons.pause),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _stop,
                      child: const Icon(Icons.stop),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.mic),
                  label: const Text('Record'),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}