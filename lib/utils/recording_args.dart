import 'package:get/get.dart';

class RecordingDetailsArgs {
  final String recordingId;
  final String? title;
  
  const RecordingDetailsArgs({required this.recordingId, this.title});
  
  @override
  String toString() => 'RecordingDetailsArgs(recordingId: $recordingId, title: $title)';
}

class RecordingArgsParser {
  static RecordingDetailsArgs? parse(dynamic a) {
    // Case A: already typed
    if (a is RecordingDetailsArgs) return a;

    // Case B: map-like
    if (a is Map) {
      final id = a['recordingId'] ?? a['recording_id'] ?? a['id'];
      if (id != null && id.toString().isNotEmpty) {
        return RecordingDetailsArgs(
          recordingId: id.toString(),
          title: a['title']?.toString(),
        );
      }
    }

    // Case C: named route params (?recordingId=)
    final p = Get.parameters;
    final pid = p['recordingId'] ?? p['recording_id'] ?? p['id'];
    if (pid != null && pid.toString().isNotEmpty) {
      return RecordingDetailsArgs(recordingId: pid.toString());
    }

    return null;
  }
}