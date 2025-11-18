import 'dart:math' as math;
import 'package:flutter/material.dart';

class RecordWaveform extends StatelessWidget {
  const RecordWaveform({
    super.key,
    required this.amplitude, // 0.0 – 1.0
  });

  final double amplitude;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF8C5BFF).withOpacity(0.35), // purple accent
              const Color(0xFF4EC5FF).withOpacity(0.35), // blue accent
            ],
          ),
        ),
        child: CustomPaint(
          painter: _SimpleWaveformPainter(amplitude),
        ),
      ),
    );
  }
}

class _SimpleWaveformPainter extends CustomPainter {
  _SimpleWaveformPainter(this.amplitude);

  final double amplitude; // expected 0.0 – 1.0

  @override
  void paint(Canvas canvas, Size size) {
    // Clamp amplitude to sane range
    final amp = amplitude.clamp(0.0, 1.0);

    // Base color that brightens slightly with amplitude
    final baseColor = Color.lerp(
      const Color(0xFFE6D9FF),  // low amplitude: softer
      const Color(0xFFFFFFFF),  // high amplitude: brighter
      amp,
    )!;

    final paint = Paint()
      ..color = baseColor.withOpacity(0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    // Overall bar height scales strongly with amplitude
    // amp≈0 -> ~15% height, amp≈1 -> ~100% of available height
    final maxAmpHeight = size.height * (0.15 + 0.85 * amp);

    const barCount = 36;
    final spacing = size.width / (barCount + 4);

    for (int i = 0; i < barCount; i++) {
      final x = spacing * (i + 2);

      // Center envelope: center bars a bit taller, edges still active
      final centerOffset = (i - barCount / 2).abs() / (barCount / 2);
      // 0 at center, 1 at edges
      final envelope = 1.0 - centerOffset * 0.4;
      // Center = 1.0, edges = 0.6 (still moving)

      // Simple deterministic "jitter" so bars aren't identical
      // Uses sin() based on index + amplitude so animation shifts with input
      final jitterSeed = (i * 0.65) + amp * 5.0;
      final jitter = 0.85 + 0.3 * (math.sin(jitterSeed).abs());
      // ~0.85–1.15

      final barHeight = maxAmpHeight * envelope * jitter;

      final y1 = midY - barHeight / 2;
      final y2 = midY + barHeight / 2;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleWaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}

