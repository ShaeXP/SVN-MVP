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
