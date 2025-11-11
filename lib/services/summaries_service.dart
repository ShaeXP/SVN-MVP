import 'package:supabase_flutter/supabase_flutter.dart';

class SummariesService {
  final _db = Supabase.instance.client;
  
  // map column names if needed
  Future<List<Map<String, dynamic>>> fetchPage({required int offset, required int limit}) async {
    final res = await _db
      .from('summaries')
      .select('id, recording_id, title, summary, tags, created_at')
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);
    // Ensure list<Map<String,dynamic>>
    return (res as List).cast<Map<String, dynamic>>();
  }
}
