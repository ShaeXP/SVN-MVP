import 'package:lashae_s_application/app/routes/app_routes.dart';
// lib/presentation/recording_control_screen/controller/recording_control_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // Add this import
import '../../../app/routes/recording_details_args.dart';
import '../../../services/pipeline.dart';
import '../../../services/pipeline_tracker.dart';
import '../../../services/supabase_service.dart';
import '../../../controllers/progress_controller.dart';

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

  @override
  void onInit() {
    super.onInit();
    // Listen for pipeline completion
    ever(PipelineTracker.I.status, (PipeStage stage) {
      if (stage == PipeStage.ready) {
        // Pipeline complete - navigate to summary
        final runId = PipelineTracker.I.recordingId.value;
        if (runId != null) {
          // Use Get.toNamed instead of Get.offAllNamed to avoid navigation conflicts
          Get.toNamed(
            Routes.recordingSummary,
            arguments: RecordingDetailsArgs(runId),
          );
        }
      } else if (stage == PipeStage.error) {
        // Pipeline failed - reset states
        isUploading.value = false;
        isProcessing.value = false;
      }
    });
  }

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
    print('DEBUG: Starting upload, isUploading = ${isUploading.value}');
    try {
      final pipeline = Pipeline();
      final runId = await pipeline.initRun();
      print('DEBUG: Got runId = $runId');

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
      print('DEBUG: Upload complete, isProcessing = ${isProcessing.value}');

      // Start pipeline tracking for real-time progress updates
      final tracker = PipelineTracker.I;
      tracker.start(runId, openHud: false); // Don't open HUD, just track progress
      print('DEBUG: Started pipeline tracker for runId = $runId');
      
      // Also start the new progress controller for banner display
      final progressController = Get.find<ProgressController>();
      progressController.start(runId);

      await pipeline.startAsr(runId, storagePath);

      // Don't navigate immediately - let the progress indicator show
      // The PipelineTracker will handle navigation when ready
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
