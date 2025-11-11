// lib/models/recording.dart
class Recording {
  final String id;
  final String? title;
  final String status;
  final String? storagePath;
  final String? transcriptId;
  final String userId;
  final DateTime? createdAt;
  final String? traceId;
  final String? lastError;
  final int? durationSec;

  Recording({
    required this.id,
    required this.status,
    required this.userId,
    this.title,
    this.storagePath,
    this.transcriptId,
    this.createdAt,
    this.traceId,
    this.lastError,
    this.durationSec,
  });

  factory Recording.fromMap(Map<String, dynamic> m) {
    return Recording(
      id: (m['id'] ?? '') as String,
      title: m['title'] as String?,
      status: (m['status'] ?? 'processing') as String,
      storagePath: m['storage_path'] as String?,
      transcriptId: m['transcript_id'] as String?,
      userId: (m['user_id'] ?? '') as String,
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
      traceId: m['trace_id'] as String?,
      lastError: m['last_error'] as String?,
      durationSec: m['duration_sec'] as int?,
    );
  }
}
