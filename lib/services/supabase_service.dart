// lib/services/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/env.dart';
import 'package:lashae_s_application/widgets/session_debug_overlay.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static bool _isInitialized = false;
  late final SupabaseClient _client;

  /// expose for read-only usage
  SupabaseClient get client => _client;

  /// shim for existing call sites (e.g., recording_backend_service)
  User? get currentUser => _client.auth.currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _isInitialized = true;

    Supabase.instance.client.auth.onAuthStateChange.listen((e) {
      debugPrint('AUTH event=${e.event} user=${e.session?.user.id}');
    });
  }

  // ---- Auth helpers
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Added optional [fullName] so existing call sites compile.
  /// If provided, we upsert it to a 'profiles' table (best-effort, ignored on error).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName, // <-- optional shim, safe to ignore if null
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (fullName != null && res.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
        });
      } catch (_) {
        // ignore profile write errors (keeps this a non-breaking shim)
      }
    }
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final res =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    return res;
  }
}
