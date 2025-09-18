import 'dart:io';

import '../../services/supabase_service.dart';
import '../models/recording_item.dart';
import './recording_repository.dart';
import 'package:lashae_s_application/bootstrap_supabase.dart';

class RecordingRepositorySupabase implements RecordingRepository {
  static final RecordingRepositorySupabase _instance =
      RecordingRepositorySupabase._internal();

  factory RecordingRepositorySupabase() => _instance;

  RecordingRepositorySupabase._internal();

  @override
  Future<void> upsertMetadata(RecordingItem item) async {
    try {
      final client = Supa.client;

      // Map plain RecordingItem to Supabase row using plain Strings/Lists
      await client.from('recordings').upsert(item.toSupabaseRecording());

      // Handle actions and keypoints as plain Lists<String>
      if (item.actions.isNotEmpty || item.keypoints.isNotEmpty) {
        // Check if note exists for this recording
        final existingNote = await client
            .from('notes')
            .select('id')
            .eq('recording_id', item.id)
            .maybeSingle();

        // Map to Supabase rows using plain Strings/Lists
        final noteData = {
          'title': item.title, // Plain String
          'recording_id': item.id, // Plain String
          'transcript': item.transcript, // Plain String
          'summary': item.summaryText, // Plain String
          'actions': item.actions, // Plain List<String>
          'highlights': item.keypoints, // Plain List<String>
        };

        if (existingNote != null) {
          // Update existing note
          await client
              .from('notes')
              .update(noteData)
              .eq('id', existingNote['id']);
        } else {
          // Create new note
          await client.from('notes').insert(noteData);
        }
      }
    } catch (e) {
      throw Exception('Failed to upsert recording metadata: $e');
    }
  }

  @override
  Future<String> uploadAudio(String recordingId, File audioFile) async {
    try {
      final client = Supa.client;

      // Plain String parameters only
      final filePath =
          'recordings/$recordingId/${audioFile.path.split('/').last}';

      await client.storage.from('audio').upload(filePath, audioFile);

      // Return plain String URL
      final publicUrl = client.storage.from('audio').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload audio file: $e');
    }
  }

  @override
  Future<List<RecordingItem>> fetchAll() async {
    try {
      final client = Supa.client;

      // Fetch recordings with related notes
      final response = await client.from('recordings').select('''
            id,
            title,
            transcript,
            summary,
            url,
            duration,
            duration_seconds,
            created_at,
            updated_at,
            notes!inner(
              actions,
              highlights
            )
          ''').order('created_at', ascending: false);

      // Map to plain RecordingItem objects
      return response
          .map<RecordingItem>((data) => RecordingItem.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recordings: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final client = Supa.client;

      // Plain String parameter only
      await client.from('notes').delete().eq('recording_id', id);
      await client.from('recordings').delete().eq('id', id);

      // Optional: Delete audio file from storage
      try {
        final files =
            await client.storage.from('audio').list(path: 'recordings/$id');

        for (final file in files) {
          await client.storage
              .from('audio')
              .remove(['recordings/$id/${file.name}']);
        }
      } catch (storageError) {
        // Log but don't fail the operation if storage cleanup fails
        print('Failed to delete audio files: $storageError');
      }
    } catch (e) {
      throw Exception('Failed to delete recording: $e');
    }
  }

  @override
  Future<RecordingItem?> getById(String id) async {
    try {
      final client = Supa.client;

      final response = await client.from('recordings').select('''
            id,
            title,
            transcript,
            summary,
            url,
            duration,
            duration_seconds,
            created_at,
            updated_at,
            notes(
              actions,
              highlights
            )
          ''').eq('id', id).maybeSingle();

      if (response != null) {
        // Return plain RecordingItem
        return RecordingItem.fromSupabase(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get recording by ID: $e');
    }
  }
}
