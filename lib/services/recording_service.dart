import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_guard.dart';

class RecordingService {
  final supabase = Supabase.instance.client;

  Future<String?> fetchTranscript(String recordingId) async {
    // Try transcripts table first
    try {
      final row = await supabase
          .from('transcripts')
          .select('text')
          .eq('recording_id', recordingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final txt = row?['text']?.toString();
      if (txt != null && txt.isNotEmpty) return txt;
    } catch (_) {}

    // Try note_runs table (canonical pipeline output)
    try {
      final row = await supabase
          .from('note_runs')
          .select('transcript_text')
          .eq('recording_id', recordingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final txt = row?['transcript_text']?.toString();
      if (txt != null && txt.isNotEmpty) return txt;
    } on PostgrestException catch (e) {
      // Fallback for camelCase column names or schema mismatches
      if (e.code == '42703' || (e.message?.contains('recording_id') ?? false)) {
        try {
          final row = await supabase
              .from('note_runs')
              .select('transcript_text')
              .eq('recordingId', recordingId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          final txt = row?['transcript_text']?.toString();
          if (txt != null && txt.isNotEmpty) return txt;
        } catch (_) {}
      }
    } catch (_) {}

    // In some flows the summary screen is opened with run_id instead of recording_id
    try {
      final row = await supabase
          .from('note_runs')
          .select('transcript_text')
          .eq('id', recordingId)
          .maybeSingle();
      final txt = row?['transcript_text']?.toString();
      if (txt != null && txt.isNotEmpty) return txt;
    } catch (_) {}

    // Fallback: recordings.transcript_text column (if it exists)
    try {
      final row = await supabase
          .from('recordings')
          .select('transcript_text')
          .eq('id', recordingId)
          .maybeSingle();
      final txt = row?['transcript_text']?.toString();
      if (txt != null && txt.isNotEmpty) return txt;
    } catch (_) {}

    return null;
  }

  Future<String?> fetchUserNotes(String recordingId) async {
    // Try recordings.user_notes first
    try {
      final row = await supabase
          .from('recordings')
          .select('user_notes')
          .eq('id', recordingId)
          .maybeSingle();
      final n = row?['user_notes']?.toString();
      if (n != null) return n;
    } catch (_) {}

    // Try user_notes table (recording_id, user_id, notes)
    try {
      final session = AuthGuard.requireSessionOrBounce();
      if (session != null) {
        final uid = session.user.id;
        final row = await supabase
            .from('user_notes')
            .select('notes')
            .eq('recording_id', recordingId)
            .eq('user_id', uid)
            .maybeSingle();
        final n = row?['notes']?.toString();
        if (n != null) return n;
      }
    } catch (_) {}

    // Offline fallback
    final p = await SharedPreferences.getInstance();
    return p.getString('notes_$recordingId');
  }

  Future<void> saveUserNotes(String recordingId, String notes) async {
    // Try recordings.user_notes
    try {
      await supabase.from('recordings').update({'user_notes': notes}).eq('id', recordingId);
      return;
    } catch (_) {}

    // Try user_notes upsert
    try {
      final session = AuthGuard.requireSessionOrBounce();
      if (session != null) {
        final uid = session.user.id;
        await supabase.from('user_notes').upsert({
          'recording_id': recordingId,
          'user_id': uid,
          'notes': notes,
        });
        return;
      }
    } catch (_) {}

    // Offline fallback (no backend column/table): cache locally
    final p = await SharedPreferences.getInstance();
    await p.setString('notes_$recordingId', notes);
  }
}
