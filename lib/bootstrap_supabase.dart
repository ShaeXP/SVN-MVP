import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      // no authFlowType on this version
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
