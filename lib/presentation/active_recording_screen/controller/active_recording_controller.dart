import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/app_export.dart';
import '../../../services/pipeline.dart';
import '../../../services/supabase_service.dart';

// lib/presentation/active_recording_screen/controller/active_recording_controller.dart

enum RecState { idle, recording, paused, stopped }

class ActiveRecordingController extends GetxController {
  final AudioRecorder _rec = AudioRecorder();
  final Pipeline _pipeline = Pipeline();

  final Rx<RecState> state = RecState.idle.obs;
  final RxString timerText = '00:00'.obs;
  final RxBool isSaving = false.obs;

  String? _filePath;
  DateTime? _startedAt;
  Timer? _ticker;

  Future<void> onRecordPressed() async {
    switch (state.value) {
      case RecState.recording:
        await pause();
        return;
      case RecState.paused:
        await resume();
        return;
      case RecState.idle:
      case RecState.stopped:
        await start();
        return;
    }
  }

  Future<void> start() async {
    try {
      final hasPermission = await _rec.hasPermission();
      if (!hasPermission) {
        _toast('Microphone permission required.');
        return;
      }

      final dir = await getTemporaryDirectory();
      _filePath = '${dir.path}/sv_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacHe,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _filePath!,
      );

      _startedAt = DateTime.now();
      state.value = RecState.recording;
      _startTicker();
      HapticFeedback.lightImpact();
    } catch (e) {
      _error('Record failed', e);
    }
  }

  Future<void> pause() async {
    try {
      if (await _rec.isRecording()) {
        await _rec.pause();
        state.value = RecState.paused;
        _stopTicker();
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      _error('Pause failed', e);
    }
  }

  Future<void> resume() async {
    try {
      if (await _rec.isPaused()) {
        await _rec.resume();
        state.value = RecState.recording;
        _startTicker(resume: true);
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      _error('Resume failed', e);
    }
  }

  Future<void> stop() async {
    try {
      final path = await _rec.stop();
      if (path != null) _filePath = path;
      state.value = RecState.stopped;
      _stopTicker();
      HapticFeedback.lightImpact();
    } catch (e) {
      _error('Stop failed', e);
    }
  }

  Future<void> save() async {
    if (_filePath == null || !File(_filePath!).existsSync()) {
      _toast('No audio to save.');
      return;
    }
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _toast('Please sign in to save.');
      return;
    }
    if (isSaving.value) return;

    isSaving.value = true;
    try {
      final runId = await _pipeline.initRun();

      final ext = _guessExtension(_filePath!);
      final storagePath = 'user/${user.id}/$runId$ext';

      final signedUrl = await _pipeline.signUpload(storagePath);
      final bytes = await File(_filePath!).readAsBytes();
      await _uploadBytesPut(signedUrl, bytes, _contentTypeForExtension(ext));

      final elapsedMs = _startedAt == null
          ? 0
          : DateTime.now().difference(_startedAt!).inMilliseconds;
      await _pipeline.insertRecording(
        runId: runId,
        storagePathOrUrl: storagePath,
        durationMs: elapsedMs,
      );

      await _pipeline.startAsr(runId, storagePath);

      Get.offAllNamed(
        AppRoutes.recordingSummaryScreen,
        arguments: {'run_id': runId},
      );
      _toast('Saved to library');
    } catch (e) {
      _error('Save failed', e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> redo() async {
    try {
      await _rec.stop();
    } catch (_) {}
    _filePath = null;
    _startedAt = null;
    timerText.value = '00:00';
    state.value = RecState.idle;
    _stopTicker();
  }

  void _startTicker({bool resume = false}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _startedAt;
      if (started == null) return;
      final diff = DateTime.now().difference(started);
      final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      timerText.value = '$m:$s';
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _guessExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a')) return '.m4a';
    if (lower.endsWith('.aac')) return '.aac';
    if (lower.endsWith('.wav')) return '.wav';
    if (lower.endsWith('.mp3')) return '.mp3';
    if (lower.endsWith('.webm')) return '.webm';
    return '.m4a';
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
      String signedUrl, Uint8List bytes, String contentType) async {
    final res = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Upload failed: ${res.statusCode}');
    }
  }

  void _toast(String msg) {
    Get.snackbar('Recording', msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.gray_50,
        colorText: appTheme.blue_gray_900);
  }

  void _error(String prefix, Object e) {
    Get.snackbar(prefix, e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700);
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _rec.dispose();
    super.onClose();
  }
}
