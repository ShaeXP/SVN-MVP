import 'package:supabase_flutter/supabase_flutter.dart';

class DbSchemaProbe {
  DbSchemaProbe(this._client);
  final SupabaseClient _client;
  Set<String>? _cols;

  Future<Set<String>> columns() async {
    if (_cols != null) return _cols!;
    try {
      // Try to infer columns from a sample row (works even w/ RLS if you own rows)
      final row = await _client.from('recordings').select('*').limit(1).maybeSingle();
      if (row != null) {
        _cols = row.keys.map((k) => k.toString()).toSet();
        return _cols!;
      }
    } catch (_) { /* ignore */ }

    // Fallback to known baseline keys that previously worked in this app.
    _cols = <String>{'id','user_id','created_at','storage_path','status','trace_id'};
    return _cols!;
  }

  Future<bool> has(String col) async => (await columns()).contains(col);
}
