// lib/ui/widgets/mic_waveform.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// MicWaveform renders a mirrored bar waveform from a rolling buffer of amplitudes in dBFS (-60..0).
/// Provide [samplesDb] as the latest buffer; it will draw smoothly with an animated repaint.
class MicWaveform extends StatelessWidget {
  const MicWaveform({
    super.key,
    required this.samplesDb,
    this.height = 80,
    this.barWidth = 3,
    this.gap = 2,
    this.color,
    this.bgColor,
  });

  /// Most recent items at the end. Values in decibels: -60 (silence-ish) to 0 (max).
  final List<double> samplesDb;
  final double height;
  final double barWidth;
  final double gap;
  final Color? color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final bg = bgColor ?? Theme.of(context).colorScheme.surface;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BarsPainter(samplesDb: samplesDb, color: c, bgColor: bg, barWidth: barWidth, gap: gap),
        size: Size(double.infinity, height),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.samplesDb,
    required this.color,
    required this.bgColor,
    required this.barWidth,
    required this.gap,
  });

  final List<double> samplesDb;
  final Color color;
  final Color bgColor;
  final double barWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Background (subtle)
    final bg = Paint()..color = bgColor.withValues(alpha: 0.5);
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(r, bg);

    // Convert dBFS [-60..0] to normalized [0..1]
    double norm(double db) => db.isNaN ? 0.0 : max(0, 1 + db / 60.0);

    // Compute bars we can fit
    final per = barWidth + gap;
    final count = (size.width / per).floor();
    final start = samplesDb.length > count ? samplesDb.length - count : 0;

    final mid = size.height / 2;
    for (int i = 0; i < count; i++) {
      final idx = start + i;
      final db = (idx >= 0 && idx < samplesDb.length) ? samplesDb[idx] : -60.0;
      final h = max(2.0, norm(db) * (size.height - 10)); // keep some padding
      final x = i * per + gap / 2;
      final top = mid - h / 2;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, top, barWidth, h), const Radius.circular(2));
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.samplesDb != samplesDb || old.color != color || old.barWidth != barWidth || old.gap != gap;
}

