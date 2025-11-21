import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ask_session.dart';
import 'supabase_service.dart';
import 'logger.dart';

class AskSessionsService {
  AskSessionsService._();

  static final AskSessionsService instance = AskSessionsService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<AskSession>> fetchRecentSessions({int limit = 5}) async {
    try {
      final response = await _client
          .from('ask_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = (response as List).cast<Map<String, dynamic>>();

      return rows.map(AskSession.fromMap).toList();
    } catch (e, st) {
      // Log the error but do not crash the app
      logx(
        '[ASK_SESSIONS] Failed to fetch recent sessions: $e',
        tag: 'ASK_SESSIONS',
        error: e,
        stack: st,
      );
      debugPrint('[ASK_SESSIONS] Failed to fetch recent sessions: $e');
      debugPrint('$st');
      return [];
    }
  }
}

