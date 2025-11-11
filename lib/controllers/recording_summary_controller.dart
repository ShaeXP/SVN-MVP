import 'dart:async';
import 'package:get/get.dart';
import '../services/recording_service.dart';

class RecordingSummaryController extends GetxController {
  final service = RecordingService();
  final transcript = RxnString();
  final notes = ''.obs;
  final saving = false.obs;
  final hasLoaded = false.obs;

  late final String recordingId;

  Timer? _debounce;

  Future<void> initWith(String id) async {
    recordingId = id;
    final t = await service.fetchTranscript(id);
    transcript.value = t;
    final n = await service.fetchUserNotes(id) ?? '';
    notes.value = n;
    hasLoaded.value = true;
  }

  void onNotesChanged(String v) {
    notes.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      saving.value = true;
      try { 
        await service.saveUserNotes(recordingId, notes.value); 
      } finally { 
        saving.value = false; 
      }
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
