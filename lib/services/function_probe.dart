// lib/services/function_probe.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/env.dart';

class FunctionProbe {
  static final _supabase = Supabase.instance.client;

  /// Ping the sv_run_pipeline health endpoint
  static Future<Map<String, dynamic>> ping() async {
    try {
      final projectUrl = Env.supabaseUrl;
      debugPrint('[FunctionProbe] Project URL: $projectUrl');
      
      final response = await _supabase.functions.invoke(
        'sv_run_pipeline',
        headers: {
          'x-path': '/health',
        },
      );
      
      debugPrint('[FunctionProbe] Health response: status=${response.status}, data=${response.data}');
      
      return {
        'status': response.status,
        'data': response.data,
        'projectUrl': projectUrl,
        'success': response.status == 200,
      };
    } catch (e) {
      debugPrint('[FunctionProbe] Health check failed: $e');
      return {
        'status': 0,
        'data': null,
        'projectUrl': Env.supabaseUrl,
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
