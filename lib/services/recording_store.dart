import 'dart:async';
import 'dart:io';

import '../data/repositories/recording_repository.dart';
import '../data/repositories/recording_repository_supabase.dart';
import '../data/models/recording_item.dart';
import '../domain/recordings/recording_status.dart';
import '../services/logger.dart';

class RecordingStore {
  RecordingStore._();
  static final RecordingStore instance = RecordingStore._();

  // In-memory storage - ensure plain types only
  final Map<String, RecordingItem> _items = {};

  // Stream controller for reactive updates
  final StreamController<List<RecordingItem>> _streamController =
      StreamController<List<RecordingItem>>.broadcast();

  // Repository instance
  final RecordingRepository _repository = RecordingRepositorySupabase();

  // Track current recording ID
  String? _currentRecordingId;

  // Getters
  String? get currentId => _currentRecordingId;
  Stream<List<RecordingItem>> get stream => _streamController.stream;

  /// Set current recording ID
  void setCurrentId(String recordingId) {
    _currentRecordingId = recordingId;
  }

  /// Clear current recording ID
  void clearCurrentId() {
    _currentRecordingId = null;
  }

  /// Add or update recording item (with write-through to database)
  Future<void> addOrUpdate({
    required String id,
    String? userId,
    DateTime? createdAt,
    int? durationSec,
    RecordingStatus? status,
    String? storagePath,
    String? transcriptId,
    String? summaryId,
    String? traceId,
    String? title,
    String? date,
    String? duration,
    String? audioUrl,
    String? transcript,
    String? summaryText,
    List<String>? actions,
    List<String>? keypoints,
  }) async {
    // Look up existing item
    final existing = _items[id];

    RecordingItem item;

    if (existing == null) {
      // Create new item with defaults for null values
      item = RecordingItem(
        id: id,
        userId: userId ?? 'unknown',
        createdAt: createdAt ?? DateTime.now(),
        durationSec: durationSec ?? 0,
        status: status ?? RecordingStatus.local,
        storagePath: storagePath ?? '',
        transcriptId: transcriptId,
        summaryId: summaryId,
        traceId: traceId,
        title: title ?? "Recording ${DateTime.now().toIso8601String()}",
        date: date ?? DateTime.now().toIso8601String(),
        duration: duration ?? "0:00",
        audioUrl: audioUrl,
        transcript: transcript,
        summaryText: summaryText,
        actions: actions ?? <String>[],
        keypoints: keypoints ?? <String>[],
      );
    } else {
      // Update existing item using copyWith - field-by-field merge
      item = existing.copyWith(
        userId: userId,
        createdAt: createdAt,
        durationSec: durationSec,
        status: status,
        storagePath: storagePath,
        transcriptId: transcriptId,
        summaryId: summaryId,
        traceId: traceId,
        title: title,
        date: date,
        duration: duration,
        audioUrl: audioUrl,
        transcript: transcript,
        summaryText: summaryText,
        actions: actions,
        keypoints: keypoints,
      );
    }

    // Optimistic update - add RecordingItem to memory first
    _items[item.id] = item;
    _emitList();

    try {
      // Write-through to database
      await _repository.upsertMetadata(item);
      logx('Recording item updated: ${item.id}', tag: 'STORE');
    } catch (e) {
      // Rollback optimistic update on failure
      if (existing != null) {
        _items[existing.id] = existing;
      } else {
        _items.remove(item.id);
      }
      _emitList();
      logx('Failed to update recording item: $e', tag: 'STORE', error: e);
      rethrow;
    }
  }

  /// Update recording status
  Future<void> updateStatus(String id, RecordingStatus status) async {
    final existing = _items[id];
    if (existing != null) {
      await addOrUpdate(
        id: id,
        status: status,
        // Keep all existing values
        userId: existing.userId,
        createdAt: existing.createdAt,
        durationSec: existing.durationSec,
        storagePath: existing.storagePath,
        transcriptId: existing.transcriptId,
        summaryId: existing.summaryId,
        traceId: existing.traceId,
        title: existing.title,
        date: existing.date,
        duration: existing.duration,
        audioUrl: existing.audioUrl,
        transcript: existing.transcript,
        summaryText: existing.summaryText,
        actions: existing.actions,
        keypoints: existing.keypoints,
      );
    }
  }

  /// Remove recording item (with write-through to database)
  Future<void> remove(String id) async {
    // Store item for potential rollback
    final removedItem = _items[id];

    // Optimistic update - remove from memory first
    _items.remove(id);
    _emitList();

    try {
      // Write-through to database
      await _repository.delete(id);
      logx('Recording item removed: $id', tag: 'STORE');
    } catch (e) {
      // Rollback optimistic update on failure
      if (removedItem != null) {
        _items[id] = removedItem;
        _emitList();
      }
      logx('Failed to remove recording item: $e', tag: 'STORE', error: e);
      rethrow;
    }
  }

  /// Get recording by ID
  RecordingItem? getById(String id) {
    return _items[id];
  }

  /// Get list of all recordings
  List<RecordingItem> list() {
    final items = _items.values.toList();
    // Sort by creation date (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Get recordings by status
  List<RecordingItem> getByStatus(RecordingStatus status) {
    return _items.values.where((item) => item.status == status).toList();
  }

  /// Fetch all recordings from database and update store
  Future<void> fetchAll() async {
    try {
      final recordings = await _repository.fetchAll();

      // Clear and repopulate store
      _items.clear();
      for (final recording in recordings) {
        _items[recording.id] = recording;
      }

      _emitList();
      logx('Fetched ${recordings.length} recordings from database', tag: 'STORE');
    } catch (e) {
      logx('Failed to fetch recordings: $e', tag: 'STORE', error: e);
      throw Exception('Failed to fetch recordings: $e');
    }
  }

  /// Upload audio file for recording
  Future<String> uploadAudio(String recordingId, File audioFile) async {
    try {
      final url = await _repository.uploadAudio(recordingId, audioFile);
      logx('Audio uploaded for recording: $recordingId', tag: 'STORE');
      return url;
    } catch (e) {
      logx('Failed to upload audio for recording $recordingId: $e', tag: 'STORE', error: e);
      rethrow;
    }
  }

  /// Emit current list to stream subscribers
  void _emitList() {
    _streamController.add(list());
  }

  /// Clear all data (for logout, etc.)
  void clear() {
    _items.clear();
    _emitList();
    logx('Recording store cleared', tag: 'STORE');
  }

  /// Dispose resources
  void dispose() {
    _streamController.close();
  }
}
