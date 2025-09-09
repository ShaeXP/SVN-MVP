import 'dart:async';
import 'dart:io';

import '../data/repositories/recording_repository.dart';
import '../data/repositories/recording_repository_supabase.dart';
import '../data/models/recording_item.dart';

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
    } catch (e) {
      // Rollback optimistic update on failure
      if (existing != null) {
        _items[existing.id] = existing;
      } else {
        _items.remove(item.id);
      }
      _emitList();
      rethrow;
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
    } catch (e) {
      // Rollback optimistic update on failure
      if (removedItem != null) {
        _items[id] = removedItem;
        _emitList();
      }
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
    // Sort by title for consistent ordering
    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
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
    } catch (e) {
      throw Exception('Failed to fetch recordings: $e');
    }
  }

  /// Upload audio file for recording
  Future<String> uploadAudio(String recordingId, File audioFile) async {
    return await _repository.uploadAudio(recordingId, audioFile);
  }

  /// Emit current list to stream subscribers
  void _emitList() {
    _streamController.add(list());
  }

  /// Clear all data (for logout, etc.)
  void clear() {
    _items.clear();
    _emitList();
  }

  /// Dispose resources
  void dispose() {
    _streamController.close();
  }
}
