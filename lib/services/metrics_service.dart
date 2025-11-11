// lib/services/metrics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart'; // AUTH-GATE: Added for navigation
import '../app/routes/app_routes.dart'; // AUTH-GATE: Added for Routes.loginScreen

const _projectRef = 'gnskowrijoouemlptrvr';
Uri _metricsUri(int hours) =>
    Uri.https('$_projectRef.functions.supabase.co', '/sv_metrics', {'hours': '$hours'});

class SvMetrics {
  final DateTime since, until;
  final int total, success, fail, sent200, dup409;
  final double? successRate;
  final int? p50, p90, p95, avg, max;
  final int? avgTrans, avgSum, avgEmail;
  final DateTime? lastRunAt;

  SvMetrics({
    required this.since,
    required this.until,
    required this.total,
    required this.success,
    required this.fail,
    required this.sent200,
    required this.dup409,
    required this.successRate,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.avg,
    required this.max,
    required this.avgTrans,
    required this.avgSum,
    required this.avgEmail,
    required this.lastRunAt,
  });

  factory SvMetrics.fromJson(Map<String, dynamic> j) {
    final win = j['window'] as Map<String, dynamic>;
    final counts = j['counts'] as Map<String, dynamic>;
    final t = j['t_total_ms'] as Map<String, dynamic>;
    final stages = j['stages_avg_ms'] as Map<String, dynamic>;
    int? _i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt();

    return SvMetrics(
      since: DateTime.parse(win['since'] as String),
      until: DateTime.parse(win['until'] as String),
      total: counts['total'] as int? ?? 0,
      success: counts['success'] as int? ?? 0,
      fail: counts['fail'] as int? ?? 0,
      sent200: counts['sent_200'] as int? ?? 0,
      dup409: counts['duplicate_409'] as int? ?? 0,
      successRate: (j['success_rate'] as num?)?.toDouble(),
      p50: _i(t, 'p50'),
      p90: _i(t, 'p90'),
      p95: _i(t, 'p95'),
      avg: _i(t, 'avg'),
      max: _i(t, 'max'),
      avgTrans: _i(stages, 'transcribe'),
      avgSum: _i(stages, 'summarize'),
      avgEmail: _i(stages, 'email'),
      lastRunAt: (j['last_run_at'] as String?) != null ? DateTime.parse(j['last_run_at'] as String) : null,
    );
  }
}

Future<SvMetrics> fetchMetrics({int hours = 168}) async {
  final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
  if (jwt == null) {
    // AUTH-GATE: Redirect to login if not signed in
    Get.offAllNamed(Routes.login);
    throw Exception('Not signed in');
  }
  final res = await http.get(_metricsUri(hours), headers: {'Authorization': 'Bearer $jwt'});
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  final j = jsonDecode(res.body) as Map<String, dynamic>;
  return SvMetrics.fromJson(j);
}

// helpers
String msToS(int? ms) {
  if (ms == null) return '—';
  final s = ms / 1000.0;
  return s.toStringAsFixed(s < 10 ? 2 : 1) + 's';
}

String pct(double? r) {
  if (r == null) return '—';
  return (r * 100).toStringAsFixed(1) + '%';
}
