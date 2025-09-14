import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Env {
  static Map<String, dynamic>? _data;

  /// Loads env.json from assets into memory
  static Future<void> load() async {
    final raw = await rootBundle.loadString('env.json');
    _data = json.decode(raw) as Map<String, dynamic>;
  }

  /// Helper to safely fetch values
  static String? getString(String key) => _data?[key]?.toString();

  /// Example typed getters
  static String get appEnv => getString('APP_ENV') ?? 'development';

  static int get maxSummaryTokens =>
      int.tryParse(getString('MAX_SUMMARY_TOKENS') ?? '600') ?? 600;

  static String? get supabaseUrl => getString('SUPABASE_URL');
  static String? get supabaseAnonKey => getString('SUPABASE_ANON_KEY');

  static String? get deepgramKey => getString('DEEPGRAM_API_KEY');
  static String? get assemblyKey => getString('ASSEMBLYAI_API_KEY');

  static String? get openaiKey => getString('OPENAI_API_KEY');
  static String? get openrouterKey => getString('OPENROUTER_API_KEY');
}
