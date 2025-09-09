class RecordingItem {
  String id;
  String title;
  String date;
  String duration;
  String? audioUrl;
  String? transcript;
  String? summaryText;
  List<String> actions;
  List<String> keypoints;

  RecordingItem({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    this.audioUrl,
    this.transcript,
    this.summaryText,
    List<String>? actions,
    List<String>? keypoints,
  })  : actions = actions ?? <String>[],
        keypoints = keypoints ?? <String>[];

  // Conversion methods for backward compatibility
  factory RecordingItem.fromSupabase(Map<String, dynamic> data) {
    final actions = <String>[];
    final keypoints = <String>[];

    if (data['notes'] != null && data['notes'] is List) {
      for (var note in data['notes'] as List) {
        if (note['actions'] != null && note['actions'] is List) {
          actions.addAll(List<String>.from(note['actions']));
        }
        if (note['highlights'] != null && note['highlights'] is List) {
          keypoints.addAll(List<String>.from(note['highlights']));
        }
      }
    }

    String formatDuration(int? durationSeconds) {
      if (durationSeconds == null) return "0:00";
      final minutes = durationSeconds ~/ 60;
      final seconds = durationSeconds % 60;
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }

    String formatDate(String? isoDate) {
      if (isoDate == null) return '';
      try {
        final date = DateTime.parse(isoDate);
        final hours =
            date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
        final amPm = date.hour >= 12 ? 'PM' : 'AM';
        return "${date.month}/${date.day}/${date.year} ${hours}:${date.minute.toString().padLeft(2, '0')} $amPm";
      } catch (e) {
        return isoDate;
      }
    }

    return RecordingItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      date: formatDate(data['created_at']?.toString()),
      duration: formatDuration(data['duration_seconds'] ?? data['duration']),
      audioUrl: data['url']?.toString(),
      transcript: data['transcript']?.toString(),
      summaryText: data['summary']?.toString(),
      actions: actions,
      keypoints: keypoints,
    );
  }

  Map<String, dynamic> toSupabaseRecording() {
    return {
      'id': id,
      'title': title,
      'transcript': transcript,
      'summary': summaryText,
      'url': audioUrl,
      'duration_seconds': _parseDurationToSeconds(duration),
      'status': 'uploaded',
    };
  }

  int _parseDurationToSeconds(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }

  RecordingItem copyWith({
    String? id,
    String? title,
    String? date,
    String? duration,
    String? audioUrl,
    String? transcript,
    String? summaryText,
    List<String>? actions,
    List<String>? keypoints,
  }) {
    return RecordingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      transcript: transcript ?? this.transcript,
      summaryText: summaryText ?? this.summaryText,
      actions: actions ?? List<String>.from(this.actions),
      keypoints: keypoints ?? List<String>.from(this.keypoints),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
