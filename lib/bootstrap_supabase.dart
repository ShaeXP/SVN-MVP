import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/env.dart';

/// Global access to a single Supabase client.
class Supa {
  static bool _inited = false;
  // Deterministic initialization - no 'late'
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize once, before runApp.
  static Future<void> init() async {
    if (_inited) return;
    // Ensure env values are non-null. If your env.dart exposes nullable,
    // add the ! or make them non-null Strings in env.dart.
    final url = Env.supabaseUrl;
    final anon = Env.supabaseAnonKey;

    await Supabase.initialize(
      url: url,
      anonKey: anon,
      // Keep authOptions minimal for 2.x unless you truly need PKCE/storage.
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        // persistSession: true, // Uncomment if your supabase_flutter version supports this option
      ),
    );

    _inited = true;

    // Optional: observe auth events during development.
    client.auth.onAuthStateChange.listen((e) {
      // ignore: avoid_print
      print('AUTH event=${e.event} user=${e.session?.user.id}');
    });
  }
}
