// lib/env.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Env {
  /// In-memory store for env.json
  static Map<String, dynamic> _data = const {};

  /// Load assets/config/env.json once at startup
  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/config/env.json');
    _data = json.decode(raw) as Map<String, dynamic>;
  }

  /// Safe getter (returns null if key missing)
  static String? _get(String key) => _data[key]?.toString();

  // ---- Typed helpers (use keys exactly as in env.json) ----
  static String get appEnv => _get('APP_ENV') ?? 'development';

  static int get maxSummaryTokens =>
      int.tryParse(_get('MAX_SUMMARY_TOKENS') ?? '') ?? 600;

  static String get supabaseUrl => _get('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY') ?? '';

  static String get deepgramKey => _get('DEEPGRAM_API_KEY') ?? '';
  static String get assemblyKey => _get('ASSEMBLYAI_API_KEY') ?? '';
  static String get openaiKey => _get('OPENAI_API_KEY') ?? '';
  static String get openrouterKey => _get('OPENROUTER_API_KEY') ?? '';
}
