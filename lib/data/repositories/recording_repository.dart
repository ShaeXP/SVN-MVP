import 'dart:io';
import '../models/recording_item.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';

abstract class RecordingRepository {
  /// Upsert recording metadata - takes plain RecordingItem
  Future<void> upsertMetadata(RecordingItem item);

  /// Upload audio file and return public URL - plain String parameters
  Future<String> uploadAudio(String recordingId, File audioFile);

  /// Fetch all recordings for current user - returns plain List<RecordingItem>
  Future<List<RecordingItem>> fetchAll();

  /// Delete recording by ID - plain String parameter
  Future<void> delete(String id);

  /// Get recording by ID - plain String parameter, returns plain RecordingItem
  Future<RecordingItem?> getById(String id);
}
