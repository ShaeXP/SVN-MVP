// lib/presentation/recording_control_screen/controller/recording_control_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // Add this import
import '../../../routes/app_routes.dart';
import '../../../services/pipeline.dart';
import '../../../services/supabase_service.dart';

/// Minimal stub to keep the legacy screen compiling.
/// It does not touch the microphone or the `record` plugin.
enum RecState { idle, recording, paused, stopped }

class RecordingControlController extends GetxController {
  final Rx<RecState> currentState = RecState.idle.obs;
  final RxString timerText = '00:00'.obs;

  // Add missing properties
  final RxBool isUploading = false.obs;
  final RxBool isProcessing = false.obs;

  Timer? _ticker;
  DateTime? _startedAt;

  // Add recording data storage
  Uint8List? _audioFile;
  int? _durationMs;

  void start() {
    currentState.value = RecState.recording;
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = _startedAt;
      if (s == null) return;
      final d = DateTime.now().difference(s);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      timerText.value = '$mm:$ss';
    });
  }

  void pause() {
    currentState.value = RecState.paused;
    _ticker?.cancel();
  }

  void resume() {
    start();
  }

  void stop() {
    currentState.value = RecState.stopped;
    _ticker?.cancel();
  }

  // Add missing method to set recording data
  void setRecordingData(Uint8List audioFile, int durationMs) {
    _audioFile = audioFile;
    _durationMs = durationMs;
  }

  // Add missing save method
  Future<void> onSavePressed() async {
    if (_audioFile == null || _durationMs == null) {
      throw Exception('No recording data to save');
    }

    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to save');
    }

    isUploading.value = true;
    try {
      final pipeline = Pipeline();
      final runId = await pipeline.initRun();

      // For web recordings, assume webm format
      final ext = '.webm';
      final storagePath = 'user/${user.id}/$runId$ext';

      final signedUrl = await pipeline.signUpload(storagePath);
      await uploadBytesPut(signedUrl, _audioFile!);

      await pipeline.insertRecording(
        runId: runId,
        storagePathOrUrl: storagePath,
        durationMs: _durationMs!,
      );

      isUploading.value = false;
      isProcessing.value = true;

      await pipeline.startAsr(runId, storagePath);

      Get.offAllNamed(
        AppRoutes.recordingSummaryScreen,
        arguments: {'run_id': runId},
      );
    } catch (e) {
      isUploading.value = false;
      isProcessing.value = false;
      rethrow;
    }
  }

  // Add the missing uploadBytesPut method
  Future<void> uploadBytesPut(String signedUrl, Uint8List bytes) async {
    final res = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': 'audio/webm'},
      body: bytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Upload failed: ${res.statusCode}');
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}