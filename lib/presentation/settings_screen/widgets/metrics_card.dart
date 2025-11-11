import 'package:flutter/material.dart';
import '../../../services/metrics_service.dart';

class MetricsCard extends StatefulWidget {
  final int hours;
  const MetricsCard({super.key, this.hours = 168});

  @override
  State<MetricsCard> createState() => _MetricsCardState();
}

class _MetricsCardState extends State<MetricsCard> {
  late Future<SvMetrics> fut;

  @override
  void initState() {
    super.initState();
    fut = fetchMetrics(hours: widget.hours);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SvMetrics>(
      future: fut,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _CardShell(
            child: Padding(padding: EdgeInsets.all(16), child: Text('Loading metrics…')),
          );
        }
        if (snap.hasError) {
          return _CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Metrics error: ${snap.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        final m = snap.data!;
        return _CardShell(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pipeline metrics (last ${widget.hours}h)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _kv('Success rate', pct(m.successRate)),
                _kv('Total runs', '${m.total}'),
                _kv('Sent (200)', '${m.sent200}'),
                _kv('Deduped (409)', '${m.dup409}'),
              ]),
              const Divider(height: 20),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _kv('TTFN p50', msToS(m.p50)),
                _kv('p90', msToS(m.p90)),
                _kv('p95', msToS(m.p95)),
                _kv('avg', msToS(m.avg)),
              ]),
              const Divider(height: 20),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _kv('Transcribe avg', msToS(m.avgTrans)),
                _kv('Summarize avg', msToS(m.avgSum)),
                _kv('Email avg', msToS(m.avgEmail)),
              ]),
              if (m.lastRunAt != null) ...[
                const SizedBox(height: 8),
                Text('Last run: ${m.lastRunAt!.toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
          ),
        );
      },
    );
  }
}

Widget _kv(String k, String v) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  ]);
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}
