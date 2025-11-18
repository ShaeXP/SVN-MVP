import 'dart:convert';
import 'package:flutter/foundation.dart';

class UploadMetric {
  final String recordingId;
  final int sizeBytes;
  final int elapsedMs;
  final DateTime startedAt;

  UploadMetric({
    required this.recordingId,
    required this.sizeBytes,
    required this.elapsedMs,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
        'recordingId': recordingId,
        'sizeBytes': sizeBytes,
        'elapsedMs': elapsedMs,
        'startedAt': startedAt.toIso8601String(),
      };
}

class PipelineMetric {
  final String recordingId;
  final int totalMs;

  PipelineMetric({
    required this.recordingId,
    required this.totalMs,
  });

  Map<String, dynamic> toJson() => {
        'recordingId': recordingId,
        'totalMs': totalMs,
      };
}

class MetricsTracker {
  MetricsTracker._internal();

  static final MetricsTracker _instance = MetricsTracker._internal();
  static MetricsTracker get I => _instance;

  final List<UploadMetric> uploads = [];
  final List<PipelineMetric> pipelines = [];
  // Track pipeline start times (debug only)
  final Map<String, DateTime> _pipelineStartTimes = {};

  void trackUpload({
    required String recordingId,
    required int sizeBytes,
    required int elapsedMs,
    required DateTime startedAt,
  }) {
    debugPrint('[METRICS] trackUpload id=$recordingId size=$sizeBytes elapsed=${elapsedMs}ms');
    uploads.add(UploadMetric(
      recordingId: recordingId,
      sizeBytes: sizeBytes,
      elapsedMs: elapsedMs,
      startedAt: startedAt,
    ));
  }

  void trackPipelineStart(String recordingId) {
    debugPrint('[METRICS] trackPipelineStart id=$recordingId');
    _pipelineStartTimes[recordingId] = DateTime.now();
  }

  void trackPipeline({
    required String recordingId,
    required int totalMs,
  }) {
    debugPrint('[METRICS] trackPipeline id=$recordingId total=${totalMs}ms');
    pipelines.add(PipelineMetric(
      recordingId: recordingId,
      totalMs: totalMs,
    ));
    _pipelineStartTimes.remove(recordingId);
  }

  void trackPipelineCompletion(String recordingId) {
    final startTime = _pipelineStartTimes[recordingId];
    if (startTime != null) {
      final totalMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[METRICS] trackPipelineCompletion id=$recordingId total=${totalMs}ms');
      trackPipeline(
        recordingId: recordingId,
        totalMs: totalMs,
      );
    } else {
      debugPrint('[METRICS] trackPipelineCompletion id=$recordingId - WARNING: no start time found');
    }
  }

  void clear() {
    debugPrint('[METRICS] clear() - clearing ${uploads.length} uploads and ${pipelines.length} pipelines');
    uploads.clear();
    pipelines.clear();
    _pipelineStartTimes.clear();
  }

  String toPrettyJson() {
    final data = {
      'uploads': uploads.map((u) => u.toJson()).toList(),
      'pipelines': pipelines.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

class MetricsSummary {
  final int uploadCount;
  final int? uploadMinMs;
  final int? uploadMaxMs;
  final double? uploadAvgMs;

  final int pipelineCount;
  final int? pipelineMinMs;
  final int? pipelineMaxMs;
  final double? pipelineAvgMs;

  MetricsSummary({
    required this.uploadCount,
    required this.uploadMinMs,
    required this.uploadMaxMs,
    required this.uploadAvgMs,
    required this.pipelineCount,
    required this.pipelineMinMs,
    required this.pipelineMaxMs,
    required this.pipelineAvgMs,
  });
}

extension MetricsTrackerSummary on MetricsTracker {
  MetricsSummary buildSummary() {
    debugPrint('[METRICS] buildSummary() - uploads: ${uploads.length}, pipelines: ${pipelines.length}');
    int? minUpload, maxUpload;
    double? avgUpload;
    if (uploads.isNotEmpty) {
      minUpload = uploads.map((u) => u.elapsedMs).reduce((a, b) => a < b ? a : b);
      maxUpload = uploads.map((u) => u.elapsedMs).reduce((a, b) => a > b ? a : b);
      final total = uploads.fold<int>(0, (sum, u) => sum + u.elapsedMs);
      avgUpload = total / uploads.length;
    }

    int? minPipe, maxPipe;
    double? avgPipe;
    if (pipelines.isNotEmpty) {
      minPipe = pipelines.map((p) => p.totalMs).reduce((a, b) => a < b ? a : b);
      maxPipe = pipelines.map((p) => p.totalMs).reduce((a, b) => a > b ? a : b);
      final total = pipelines.fold<int>(0, (sum, p) => sum + p.totalMs);
      avgPipe = total / pipelines.length;
    }

    return MetricsSummary(
      uploadCount: uploads.length,
      uploadMinMs: minUpload,
      uploadMaxMs: maxUpload,
      uploadAvgMs: avgUpload,
      pipelineCount: pipelines.length,
      pipelineMinMs: minPipe,
      pipelineMaxMs: maxPipe,
      pipelineAvgMs: avgPipe,
    );
  }
}

