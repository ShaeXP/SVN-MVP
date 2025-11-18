import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaveform extends StatefulWidget {
  final bool isActive; // true when recording
  /// Optional audio level, normalized 0.0–1.0. When provided, use it
  /// to subtly scale the wave amplitude.
  final double? level;

  const AnimatedWaveform({
    super.key,
    required this.isActive,
    this.level,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = widget.isActive ? _controller.value : 0.0;
        return CustomPaint(
          painter: _WaveformPainter(
            progress: t,
            isActive: widget.isActive,
            level: widget.level,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final double? level;

  _WaveformPainter({
    required this.progress,
    required this.isActive,
    this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFA26DC6), // Deep Purple
        Color(0xFF6D69BD), // Indigo Blue
        Color(0xFF44739F), // Teal Blue
      ],
    );

    final bool active = isActive;
    final double baseOpacity = active ? 1.0 : 0.4; // ~40% when idle

    // Compute levelBoost for amplitude scaling
    final normalizedLevel = (level ?? 0.0).clamp(0.0, 1.0);
    final levelBoost = isActive ? (0.6 + normalizedLevel * 0.8) : 0.5;

    Paint makePaint(double strokeWidth, double alphaMultiplier) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = gradient.createShader(rect)
        ..color = Colors.white.withOpacity(baseOpacity * alphaMultiplier);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..isAntiAlias = true
      ..color = active
          ? const Color(0x55A26DC6) // a bit stronger when active
          : const Color(0x33A26DC6); // softer when idle

    final midY = size.height * 0.5;
    final amplitude = size.height * 0.35 * (isActive ? levelBoost : 0.5);
    final width = size.width;

    Path buildWave({
      required double frequency,
      required double phaseShift,
      required double amplitudeScale,
    }) {
      final path = Path();
      for (double x = 0; x <= width; x += 3) {
        final t = x / width;
        final phase = (progress * 2 * math.pi) + phaseShift;

        final y = midY +
            math.sin(t * frequency * 2 * math.pi + phase) *
                amplitude *
                amplitudeScale;

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    // Main wave
    final mainPath = buildWave(
      frequency: 1.2,
      phaseShift: 0.0,
      amplitudeScale: 1.0,
    );

    // Secondary waves (slightly offset)
    final highFreqPath = buildWave(
      frequency: 2.0,
      phaseShift: -math.pi / 4,
      amplitudeScale: 0.5,
    );
    final lowFreqPath = buildWave(
      frequency: 0.8,
      phaseShift: math.pi / 3,
      amplitudeScale: 0.7,
    );

    // Optional tiny stroke bump when active
    final double mainStroke = active ? 4.5 : 4.0;
    final double secondaryStroke = active ? 3.2 : 2.8;

    // Glow under main path
    canvas.drawPath(mainPath, glowPaint);

    // Draw waves
    canvas.drawPath(mainPath, makePaint(mainStroke, 1.0));
    canvas.drawPath(highFreqPath, makePaint(secondaryStroke, 0.7));
    canvas.drawPath(lowFreqPath, makePaint(secondaryStroke, 0.6));
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || 
        oldDelegate.isActive != isActive ||
        oldDelegate.level != level;
  }
}
