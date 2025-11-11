import 'dart:async';
import 'dart:io';
// import 'package:flutter/foundation.dart' show debugPrint; // Unnecessary import
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'recording_state.dart';
import 'package:lashae_s_application/services/upload_service.dart';
import 'package:lashae_s_application/services/pipeline_service.dart';
import 'package:lashae_s_application/services/file_upload_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import 'package:lashae_s_application/presentation/shared/pipeline_hud.dart';
import 'package:lashae_s_application/data/recording_repo.dart';

class RecordingController extends GetxController {
  final state = RecState.idle.obs;
  final elapsedSec = 0.obs;
  final amplitude = 0.0.obs; // 0..1 normalized for a simple waveform
  final saving = false.obs; // NEW: disables Save while uploading
  final isUploading = false.obs; // Track upload state

  final _rec = FlutterSoundRecorder();
  Timer? _ticker;
  StreamSubscription<RecordingDisposition>? _ampSub;
  bool _sessionOpen = false;

  String? _tempPath;   // finalized after stop()
  final String _ext = 'm4a';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DI] RecordingController onInit');
    _ensureSession();
  }

  Future<void> _ensureSession() async {
    if (_sessionOpen) return;
    try {
      await _rec.openRecorder();
      _sessionOpen = true;
      debugPrint('[RecordingController] Flutter Sound session opened');
    } catch (e) {
      debugPrint('[RecordingController] Failed to open session: $e');
    }
  }

  // MM:SS clock
  String get clock {
    final s = elapsedSec.value;
    final m = s ~/ 60, r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  // --- FSM actions ---

  Future<void> start() async {
    if (state.value != RecState.idle) return;

    // Permission
    final status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      // You can surface a snackbar/toast here if desired
      return;
    }

    await _ensureSession();

    final tmp = await getTemporaryDirectory();
    final file = 'rec_${DateTime.now().millisecondsSinceEpoch}.$_ext';
    final path = p.join(tmp.path, file);

    // Configure Flutter Sound for AAC-LC .m4a at 44.1kHz mono
    await _rec.setSubscriptionDuration(const Duration(milliseconds: 100));
    
    await _rec.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );
    
    _tempPath = path;

    _startTicker();
    _listenAmplitude();
    state.value = RecState.recording;
  }

  Future<void> pause() async {
    if (state.value != RecState.recording) return;
    await _rec.pauseRecorder();
    _stopTicker();
    state.value = RecState.paused;
  }

  Future<void> resume() async {
    if (state.value != RecState.paused) return;
    await _rec.resumeRecorder();
    _startTicker();
    state.value = RecState.recording;
  }

  Future<void> stop() async {
    if (state.value != RecState.recording && state.value != RecState.paused) return;
    _stopTicker();
    final finalPath = await _rec.stopRecorder();     // <-- get finalized file path
    _cancelAmplitude();
    if (finalPath != null && finalPath.isNotEmpty) {
      _tempPath = finalPath;                 // <-- CRITICAL FIX
    }
    state.value = RecState.stopped;          // review state
  }

  Future<void> redo() async {
    _stopTicker();
    _cancelAmplitude();
    if (_tempPath != null) { try { await File(_tempPath!).delete(); } catch (_) {} }
    _tempPath = null;
    elapsedSec.value = 0;
    amplitude.value = 0;
    state.value = RecState.idle;
  }

  /// Save = upload -> create Library row -> start pipeline.
  Future<void> save() async {
    if (state.value != RecState.stopped || _tempPath == null) return;

    final f = File(_tempPath!);
    if (!await f.exists()) {
      // Try to be helpful if path moved or missing
      // ignore: avoid_print
      print('[RecordingController] file not found at $_tempPath');
      Get.snackbar('Save failed', 'Recorded file not found. Try recording again.');
      return;
    }

    if (saving.value) return;      // already saving
    saving.value = true;           // <-- start guard
    try {
      final upload = UploadService();
      final pipe = PipelineService();
      final repo = RecordingRepo();

      final relative = await upload.uploadAudio(f, _ext); // '<uid>/.../file.m4a'
      final fullPath = relative.startsWith('recordings/') ? relative : 'recordings/$relative';

      // Insert Library row and start pipeline
      final res = await repo.createRecordingRow(storagePath: fullPath);
      final recordingId = res.recordingId;

      // Start tracking the pipeline for progress updates
      PipelineTracker.I.start(recordingId);

      await pipe.runWithId(fullPath, recordingId);

      // Only show success toast after both DB insert and storage upload succeed
      Get.snackbar('Upload Queued', 'Recording uploaded successfully. You\'ll see it in Library shortly.');
      await redo(); // reset UI
    } catch (e) {
      // ignore: avoid_print
      print('[RecordingController] save error: $e');
      Get.snackbar('Save failed', e.toString());
    } finally {
      saving.value = false;        // <-- end guard
    }
  }

  // --- Internals ---

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => elapsedSec.value++);
  }

  void _stopTicker() { _ticker?.cancel(); _ticker = null; }

  void _listenAmplitude() {
    _ampSub?.cancel();
    _ampSub = _rec.onProgress!.listen((disposition) {
      // Use the decibel value from RecordingDisposition
      // Map ~[-45..0] -> [0..1] for normalized amplitude
      final db = disposition.decibels ?? -45.0;
      final norm = ((db + 45) / 45).clamp(0.0, 1.0);
      amplitude.value = norm;
    });
  }

  void _cancelAmplitude() { _ampSub?.cancel(); _ampSub = null; }

  /// Upload file via file picker
  Future<void> onUploadFilePressed(BuildContext context) async {
    if (isUploading.value) return;
    
    isUploading.value = true;
    try {
      final fileService = FileUploadService.instance;
      final result = await fileService.pickAndUploadAudioFile();
      
      if (result['success'] == true) {
        final recordingId = result['recording_id'] as String?;
        
        if (recordingId != null) {
          // Start tracking the pipeline with all available parameters
          PipelineTracker.I.start(recordingId);
          
          // Small delay to ensure database is ready, then show HUD
          Future.delayed(const Duration(milliseconds: 200), () {
            Get.bottomSheet(
              const PipelineHUD(autonavigateWhenReady: true),
              isScrollControlled: false,
              isDismissible: true,
              enableDrag: true,
            );
          });
        } else {
          // Only show success toast after both DB insert and storage upload succeed
          Get.snackbar(
            'Upload Queued',
            'Recording uploaded successfully. You\'ll see it in Library shortly.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        final message = result['message'] ?? result['error'] ?? 'Upload failed';
        final error = result['error']?.toString() ?? '';
        
        // Show appropriate error message based on failure point
        String errorTitle = 'Upload Failed';
        if (message.contains('DB insert')) {
          errorTitle = 'Upload Failed (DB insert)';
        } else if (message.contains('storage')) {
          errorTitle = 'Upload Failed (Storage)';
        }
        
        Get.snackbar(
          errorTitle,
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          messageText: Text('$message${error.isNotEmpty && error != message ? '\n\nDetails: $error' : ''}'),
        );
        // Also print to console for debugging
        // ignore: avoid_print
        print('[UPLOAD ERROR] $message\nError: $error\nFull result: $result');
      }
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload file: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      // ignore: avoid_print
      print('[UPLOAD EXCEPTION] $e');
    } finally {
      isUploading.value = false;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _cancelAmplitude();
    if (_sessionOpen) {
      _rec.closeRecorder();
      _sessionOpen = false;
    }
    super.onClose();
  }
}
