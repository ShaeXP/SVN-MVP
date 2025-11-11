// lib/services/auth.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthX {
  static final _supabase = Supabase.instance.client;

  // Returns a non-null userId or throws.
  static Future<String> requireUserId() async {
    final s = _supabase.auth.currentSession;
    if (s?.user != null) return s!.user.id;
    throw StateError('No auth session');
  }

  // For development only: sign into a low-priv dev account when no session.
  static Future<void> devAuthIfNeeded({
    required String email,
    required String password,
    bool enabled = false,
  }) async {
    if (!enabled) return;
    if (_supabase.auth.currentSession?.user != null) return;
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }
}
