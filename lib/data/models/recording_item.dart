import 'package:flutter/foundation.dart';
import '../../domain/recordings/recording_status.dart';

class RecordingItem {
  // REQUIRED PRD fields (keep existing; add missing as shown)
  final String id;
  final String userId;                 // maps from user_id|userId
  final DateTime createdAt;            // created_at|createdAt
  final int durationSec;               // duration_sec|durationSec (default 0)
  final RecordingStatus status;        // stored as string
  final String storagePath;            // storage_path|storagePath

  // Optional PRD fields
  final String? transcriptId;          // transcript_id|transcriptId
  final String? summaryId;             // summary_id|summaryId
  final String? traceId;               // trace_id|traceId

  // Existing fields (keep for backwards compatibility)
  final String title;
  final String date;
  final String duration;
  final String? audioUrl;
  final String? transcript;
  final String? summaryText;
  final List<String> actions;
  final List<String> keypoints;

  RecordingItem({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.durationSec,
    required this.status,
    required this.storagePath,
    this.transcriptId,
    this.summaryId,
    this.traceId,
    // Existing fields
    required this.title,
    required this.date,
    required this.duration,
    this.audioUrl,
    this.transcript,
    this.summaryText,
    List<String>? actions,
    List<String>? keypoints,
  }) : actions = actions ?? const <String>[],
       keypoints = keypoints ?? const <String>[];

  RecordingItem copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    int? durationSec,
    RecordingStatus? status,
    String? storagePath,
    String? transcriptId,
    String? summaryId,
    String? traceId,
    // Existing fields
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
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      durationSec: durationSec ?? this.durationSec,
      status: status ?? this.status,
      storagePath: storagePath ?? this.storagePath,
      transcriptId: transcriptId ?? this.transcriptId,
      summaryId: summaryId ?? this.summaryId,
      traceId: traceId ?? this.traceId,
      // Existing fields
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

  // Tolerant mapper (does not break existing payloads)
  factory RecordingItem.fromMap(Map<String, dynamic> map) {
    String _str(dynamic v) => (v ?? '').toString();
    int _i(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

    RecordingStatus _status(dynamic v) {
      final s = _str(v).isEmpty ? 'local' : _str(v);
      return RecordingStatus.fromString(s);
    }

    DateTime _dt(dynamic v) =>
        v is DateTime ? v : DateTime.tryParse(_str(v)) ?? DateTime.now();

    // Handle existing format for backwards compatibility
    final actions = <String>[];
    final keypoints = <String>[];

    if (map['notes'] != null && map['notes'] is List) {
      for (var note in map['notes'] as List) {
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
      id: _str(map['id']),
      userId: _str(map['user_id'] ?? map['userId']),
      createdAt: _dt(map['created_at'] ?? map['createdAt']),
      durationSec: _i(map['duration_sec'] ?? map['durationSec']),
      status: _status(map['status']),
      storagePath: _str(map['storage_path'] ?? map['storagePath']),
      transcriptId: (map['transcript_id'] ?? map['transcriptId']) as String?,
      summaryId: (map['summary_id'] ?? map['summaryId']) as String?,
      traceId: (map['trace_id'] ?? map['traceId']) as String?,
      // Existing fields
      title: map['title']?.toString() ?? '',
      date: formatDate(map['created_at']?.toString()),
      duration: formatDuration(map['duration_seconds'] ?? map['duration']),
      audioUrl: map['url']?.toString(),
      transcript: map['transcript']?.toString(),
      summaryText: map['summary']?.toString(),
      actions: actions,
      keypoints: keypoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'duration_sec': durationSec,
      'status': status.name,
      'storage_path': storagePath,
      if (transcriptId != null) 'transcript_id': transcriptId,
      if (summaryId != null) 'summary_id': summaryId,
      if (traceId != null) 'trace_id': traceId,
      // Existing fields
      'title': title,
      'transcript': transcript,
      'summary': summaryText,
      'url': audioUrl,
      'duration_seconds': _parseDurationToSeconds(duration),
    };
  }

  // Existing methods for backwards compatibility
  factory RecordingItem.fromSupabase(Map<String, dynamic> data) {
    return RecordingItem.fromMap(data);
  }

  Map<String, dynamic> toSupabaseRecording() {
    return toMap();
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Add SummaryItem model
class SummaryItem {
  final String id;
  final String recordingId;
  final String title;
  final String summary;
  final List<String> bullets;
  final List<String> actionItems;
  final List<String> tags;
  final double? confidence;
  final String summaryStyle; // 'quick_recap' | 'organized_by_topic' | 'decisions_next_steps'

  const SummaryItem({
    required this.id,
    required this.recordingId,
    required this.title,
    required this.summary,
    required this.bullets,
    required this.actionItems,
    required this.tags,
    this.confidence,
    this.summaryStyle = 'quick_recap',
  });

  factory SummaryItem.fromMap(Map<String, dynamic> map) {
    List<String> _ls(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    double? _d(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

    return SummaryItem(
      id: (map['id'] ?? '').toString(),
      recordingId: (map['recording_id'] ?? map['recordingId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      bullets: _ls(map['bullets']),
      actionItems: _ls(map['action_items'] ?? map['actionItems']),
      tags: _ls(map['tags']),
      confidence: _d(map['confidence']),
      summaryStyle: (map['summary_style'] ?? map['summaryStyle'] ?? 'quick_recap').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'recording_id': recordingId,
        'title': title,
        'summary': summary,
        'bullets': bullets,
        'action_items': actionItems,
        'tags': tags,
        if (confidence != null) 'confidence': confidence,
        'summary_style': summaryStyle,
      };
}
