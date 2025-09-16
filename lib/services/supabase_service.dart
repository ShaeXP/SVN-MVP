import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/preview_mode_detector.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const _edgeUrl =
      'https://gnskowrijoouemlptrvr.functions.supabase.co/deepgram-transcribe';
  static const _summarizeUrl =
      'https://gnskowrijoouemlptrvr.functions.supabase.co/summarize-transcript';
  static const _anon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imduc2tvd3Jpam9vdWVtbHB0cnZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0Mjc1ODQsImV4cCI6MjA3MDAwMzU4NH0.V1RCUJ6Duf_5iHzkknF58gDS1Q6L8y5xAEnK29xfmsg'; // ok in client

  /// Initialize Supabase with preview mode support
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'your_supabase_url');
      const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'your_supabase_anon_key');

      if (PreviewModeDetector.isPreviewMode) {
        // In preview mode, create no-op client if keys are not configured
        if (supabaseUrl == 'your_supabase_url' ||
            supabaseAnonKey == 'your_supabase_anon_key') {
          debugPrint('🎭 Preview mode: Using mock Supabase client');
          _client = _createNoOpClient();
          _isInitialized = true;
          return;
        }
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      if (PreviewModeDetector.isPreviewMode) {
        debugPrint('🎭 Preview mode: Supabase init failed, using no-op client');
        _client = _createNoOpClient();
        _isInitialized = true;
      } else {
        debugPrint('❌ Supabase initialization failed: $e');
        rethrow;
      }
    }
  }

  /// Create a no-op client for preview mode
  SupabaseClient _createNoOpClient() {
    // Create a mock client that won't make network requests
    // This is for preview mode only
    try {
      return SupabaseClient(
        'https://preview-mock.supabase.co',
        'preview-mock-anon-key',
      );
    } catch (e) {
      // If even mock client fails, we'll handle it in methods
      rethrow;
    }
  }

  // Auth methods with preview mode handling
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock sign up');
      throw Exception('Preview mode: Authentication not available');
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock sign in');
      throw Exception('Preview mode: Authentication not available');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  Future<void> signOut() async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock sign out');
      return;
    }

    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  // User Profile methods with preview mode handling
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock user profile');
      return {
        'id': 'preview-user-id',
        'full_name': 'Preview User',
        'email': 'preview@example.com',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock update user profile');
      return;
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _client.from('user_profiles').update({
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  // Recordings methods with preview mode handling
  Future<List<dynamic>> getUserRecordings() async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock user recordings');
      return [
        {
          'id': 'preview-recording-1',
          'title': 'Preview Recording 1',
          'created_at': DateTime.now().toIso8601String(),
          'duration': '2:30',
          'status': 'processed',
        },
        {
          'id': 'preview-recording-2',
          'title': 'Preview Recording 2',
          'created_at':
              DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
          'duration': '1:45',
          'status': 'processed',
        }
      ];
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final response = await _client
          .from('recordings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response;
    } catch (error) {
      throw Exception('Failed to get recordings: $error');
    }
  }

  Future<Map<String, dynamic>> createRecording({
    required String title,
    required String audioUrl,
    String? transcript,
    Map<String, dynamic>? metadata,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock create recording');
      return {
        'id': 'preview-recording-${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'audio_url': audioUrl,
        'transcript': transcript ?? 'Preview transcript',
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'status': 'processed',
      };
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final response = await _client
          .from('recordings')
          .insert({
            'user_id': user.id,
            'title': title,
            'audio_url': audioUrl,
            'transcript': transcript,
            'metadata': metadata,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create recording: $error');
    }
  }

  /// Upload -> Deepgram -> insert -> Summarize -> update. Returns final row + 'deepgram'.
  Future<Map<String, dynamic>> uploadTranscribeSave({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock upload transcribe save');
      await Future.delayed(Duration(seconds: 2)); // Simulate processing time
      return {
        'id': 'preview-transcript-${DateTime.now().millisecondsSinceEpoch}',
        'audio_url':
            'https://preview-mock.supabase.co/storage/v1/object/public/public-audio/preview-file.m4a',
        'transcript': {
          'text':
              'This is a preview mode transcript. The actual transcript would contain the speech-to-text results from Deepgram.',
          'confidence': 0.95,
          'words': []
        },
        'summary':
            'Preview mode summary: This would contain an AI-generated summary of the transcript.',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
        'deepgram': {
          'text':
              'This is a preview mode transcript. The actual transcript would contain the speech-to-text results from Deepgram.',
          'confidence': 0.95
        }
      };
    }

    try {
      final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}-$fileName';
      final uploadedPath = await _client.storage
          .from('public-audio')
          .uploadBinary(
              path, Uint8List.fromList(bytes),
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false));
      if (uploadedPath.isEmpty) throw Exception('Upload failed');
      final publicUrl = _client.storage.from('public-audio').getPublicUrl(path);

      // Call Deepgram transcription
      final resp = await http.post(
        Uri.parse(_edgeUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $_anon',
          'apikey': _anon,
        },
        body: jsonEncode({'audio_url': publicUrl}),
      );
      final dg = jsonDecode(resp.body);
      if (resp.statusCode != 200) {
        throw Exception(dg['error'] ?? 'Transcription failed');
      }

      // Insert transcript row
      final inserted = await _client
          .from('transcripts')
          .insert(
              {'audio_url': publicUrl, 'transcript': dg, 'status': 'completed'})
          .select()
          .single();

      // Extract transcript text and call summarize function
      String transcriptText = '';
      if (dg is Map && dg['results'] != null) {
        final results = dg['results'] as Map;
        if (results['channels'] != null) {
          final channels = results['channels'] as List;
          if (channels.isNotEmpty && channels[0]['alternatives'] != null) {
            final alternatives = channels[0]['alternatives'] as List;
            if (alternatives.isNotEmpty) {
              transcriptText = alternatives[0]['transcript'] ?? '';
            }
          }
        }
      } else if (dg is Map && dg['text'] != null) {
        transcriptText = dg['text'];
      }

      if (transcriptText.isNotEmpty) {
        try {
          // Call summarize-transcript Edge Function
          final summaryResp = await http.post(
            Uri.parse(_summarizeUrl),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $_anon',
              'apikey': _anon,
            },
            body: jsonEncode({'transcript_text': transcriptText}),
          );

          if (summaryResp.statusCode == 200) {
            final summaryData = jsonDecode(summaryResp.body);
            final summary =
                summaryData['summary'] ?? summaryData['result'] ?? '';

            // Update the row with the summary
            await _client
                .from('transcripts')
                .update({'summary': summary}).eq('id', inserted['id']);

            // Update our return data
            inserted['summary'] = summary;
          }
        } catch (e) {
          debugPrint('Summary generation failed: $e');
          // Continue without summary - don't fail the whole operation
        }
      }

      final out = Map<String, dynamic>.from(inserted);
      out['deepgram'] = dg;
      return out; // contains 'id'
    } catch (e) {
      if (PreviewModeDetector.isPreviewMode) {
        debugPrint(
            '🎭 Preview mode: Upload transcribe error, returning mock data');
        return {
          'id':
              'preview-transcript-error-${DateTime.now().millisecondsSinceEpoch}',
          'audio_url':
              'https://preview-mock.supabase.co/storage/v1/object/public/public-audio/preview-file.m4a',
          'transcript': {'error': 'Preview mode - no actual transcription'},
          'summary': null,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
          'deepgram': {'error': 'Preview mode - no actual transcription'}
        };
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTranscriptById(String id) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock fetch transcript by ID');
      return {
        'id': id,
        'audio_url':
            'https://preview-mock.supabase.co/storage/v1/object/public/public-audio/preview-file.m4a',
        'transcript': {
          'text':
              'This is a preview mode transcript that would normally be fetched from Supabase. It contains the speech-to-text results from the audio recording.',
          'confidence': 0.95,
          'words': []
        },
        'summary':
            'Preview mode summary: This recording discusses important topics and contains several key insights that would be extracted by AI analysis.',
        'status': 'completed',
        'created_at':
            DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'user_id': 'preview-user-id'
      };
    }

    try {
      final row =
          await _client.from('transcripts').select().eq('id', id).single();
      return Map<String, dynamic>.from(row);
    } catch (e) {
      throw Exception('Failed to fetch transcript: $e');
    }
  }

  // Auth state stream with preview mode handling
  Stream<AuthState> get authStateChanges {
    if (PreviewModeDetector.isPreviewMode) {
      // Return empty stream in preview mode
      return Stream.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  bool get isAuthenticated {
    if (PreviewModeDetector.isPreviewMode) {
      return false; // Always unauthenticated in preview mode
    }
    return _client.auth.currentUser != null;
  }

  User? get currentUser {
    if (PreviewModeDetector.isPreviewMode) {
      return null; // No current user in preview mode
    }
    return _client.auth.currentUser;
  }
}
