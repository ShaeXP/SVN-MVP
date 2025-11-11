// lib/services/supabase_service.dart
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/env.dart';
import 'package:lashae_s_application/widgets/session_debug_overlay.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static bool _isInitialized = false;
  // Deterministic initialization - no 'late'
  SupabaseClient get _client => Supabase.instance.client;

  /// Observable current user for GetX
  final Rx<User?> _currentUser = Rx<User?>(null);

  /// expose for read-only usage
  SupabaseClient get client => _client;

  /// Observable getter for GetX usage
  Rx<User?> get currentUser => _currentUser;

  /// shim for existing call sites (e.g., recording_backend_service)
  User? get currentUserValue => _client.auth.currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    
    _isInitialized = true;

    // Initialize the observable with current user
    final initialUser = _client.auth.currentUser;
    _currentUser.value = initialUser;

    // Set up auth state listener
    _client.auth.onAuthStateChange.listen((e) {
      // Update the observable when auth state changes
      _currentUser.value = e.session?.user;
    });

    // Force a refresh of the auth state to ensure we have the latest user
    await _refreshAuthState();
  }

  /// Force refresh the authentication state
  Future<void> _refreshAuthState() async {
    try {
      final currentUser = _client.auth.currentUser;
      _currentUser.value = currentUser;
    } catch (e) {
      // Silently handle auth refresh errors
    }
  }

  // ---- Auth helpers
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Added optional [fullName] so existing call sites compile.
  /// If provided, we upsert it to 'user_profiles' table (best-effort, ignored on error).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName, // <-- optional shim, safe to ignore if null
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (fullName != null && res.user != null) {
      try {
        await _client.from('user_profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': email,
        });
      } catch (_) {
        // ignore profile write errors (keeps this a non-breaking shim)
      }
    }
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Manually refresh the authentication state (useful for debugging)
  Future<void> refreshAuthState() async {
    await _refreshAuthState();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    try {
      // Try to fetch existing profile
      final res = await _client.from('user_profiles').select().eq('id', user.id).maybeSingle();
      
      // If no profile exists, create one (first login)
      if (res == null) {
        final newProfile = {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
        };
        
        await _client.from('user_profiles').upsert(newProfile);
        return newProfile;
      }
      
      return res;
    } catch (e) {
      // Return null on error; caller will handle gracefully
      if (kDebugMode) {
        print('[SupabaseService] getUserProfile error: $e');
      }
      return null;
    }
  }
}
