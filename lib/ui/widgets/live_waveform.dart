import 'dart:math' as math;
import 'package:flutter/material.dart';

/// LiveWaveform displays a smooth, layered waveform with dynamic gradient colors.
/// Takes a ValueNotifier<double> that provides normalized amplitude values (0.0-1.0).
class LiveWaveform extends StatefulWidget {
  const LiveWaveform({
    super.key,
    required this.amplitude,
    this.waveColor = const Color(0xFF4C6CFF), // Kept for backward compatibility
    this.layerCount = 3,
    this.curveSmoothing = 0.3,
    this.pulseSpeed = 2.0,
    this.minBarHeight = 1.0,
  });

  final ValueNotifier<double> amplitude;
  final Color waveColor; // Overridden by dynamic gradient
  final int layerCount; // Number of overlapping curves
  final double curveSmoothing; // Bezier curve tension (0.0-1.0)
  final double pulseSpeed; // Breathing animation speed
  final double minBarHeight; // Minimum height for bar accents

  @override
  State<LiveWaveform> createState() => _LiveWaveformState();
}

class _LiveWaveformState extends State<LiveWaveform>
    with SingleTickerProviderStateMixin {
  final List<double> _amplitudeHistory = [];
  static const int _maxSamples = 80; // Number of amplitude points
  double? _lastAmplitude;
  int _updateCounter = 0;
  late AnimationController _pulseController;
  double _currentAmplitude = 0.0; // Track current amplitude for gradient

  @override
  void initState() {
    super.initState();
    widget.amplitude.addListener(_updateHistory);
    _updateHistory();
    
    // Initialize pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.amplitude.removeListener(_updateHistory);
    _pulseController.dispose();
    super.dispose();
  }

  void _updateHistory() {
    final current = widget.amplitude.value;
    if (!mounted) return;
    
    _currentAmplitude = current;
    
    // Always add to history for smooth scrolling
    _amplitudeHistory.add(current);
    if (_amplitudeHistory.length > _maxSamples) {
      _amplitudeHistory.removeAt(0);
    }
    
    // Only trigger setState periodically for performance
    _updateCounter++;
    if (_lastAmplitude == null || 
        (_lastAmplitude! - current).abs() > 0.02 || 
        _updateCounter % 2 == 0) {
      _lastAmplitude = current;
      setState(() {
        // State is already updated above, this just triggers rebuild
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _WaveformPainter(
                  amplitudes: List.from(_amplitudeHistory),
                  currentAmplitude: _currentAmplitude,
                  layerCount: widget.layerCount,
                  curveSmoothing: widget.curveSmoothing,
                  pulseValue: _pulseController.value,
                  minBarHeight: widget.minBarHeight,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.amplitudes,
    required this.currentAmplitude,
    required this.layerCount,
    required this.curveSmoothing,
    required this.pulseValue,
    required this.minBarHeight,
  });

  final List<double> amplitudes;
  final double currentAmplitude;
  final int layerCount;
  final double curveSmoothing;
  final double pulseValue; // 0.0-1.0 for breathing effect
  final double minBarHeight;

  // Brand color palette
  static const Color _deepPurple = Color(0xFFA26DC6);
  static const Color _lavender = Color(0xFFAB9DDB);
  static const Color _indigoBlue = Color(0xFF6D69BD);
  static const Color _tealBlue = Color(0xFF44739F);

  /// Calculate dynamic gradient color based on amplitude
  Color _getGradientColor(double amplitude) {
    final clamped = amplitude.clamp(0.0, 1.0);
    
    if (clamped < 0.3) {
      // Low amplitude: Deep Purple → Lavender
      return Color.lerp(_deepPurple, _lavender, clamped / 0.3)!;
    } else if (clamped < 0.7) {
      // Medium amplitude: Lavender → Indigo Blue
      return Color.lerp(_lavender, _indigoBlue, (clamped - 0.3) / 0.4)!;
    } else {
      // High amplitude: Indigo Blue → Teal Blue
      return Color.lerp(_indigoBlue, _tealBlue, (clamped - 0.7) / 0.3)!;
    }
  }

  /// Generate smooth curve path using quadratic bezier curves
  Path _generateSmoothPath(List<double> points, Size size, double offsetY, double opacity) {
    if (points.isEmpty) return Path();
    
    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;
    final pointCount = points.length;
    
    if (pointCount == 1) {
      final y = centerY + (points[0] - 0.5) * size.height * 0.8;
      path.moveTo(0, y);
      path.lineTo(width, y);
      return path;
    }
    
    // Calculate spacing between points
    final spacing = width / (pointCount - 1);
    
    // Apply pulse/breathing effect (subtle scale: 0.95-1.05)
    final pulseScale = 0.95 + (pulseValue * 0.1);
    
    // Start path
    final firstY = centerY + (points[0] - 0.5) * size.height * 0.8 * pulseScale + offsetY;
    path.moveTo(0, firstY);
    
    // Generate smooth curve using quadratic bezier
    for (int i = 1; i < pointCount; i++) {
      final x = i * spacing;
      final y = centerY + (points[i] - 0.5) * size.height * 0.8 * pulseScale + offsetY;
      
      if (i == 1) {
        // First segment: use previous point as control
        final prevY = centerY + (points[i - 1] - 0.5) * size.height * 0.8 * pulseScale + offsetY;
        final controlX = (x + (i - 1) * spacing) / 2;
        final controlY = (y + prevY) / 2;
        path.quadraticBezierTo(controlX, controlY, x, y);
      } else {
        // Subsequent segments: use smooth control points
        final prevX = (i - 1) * spacing;
        final prevY = centerY + (points[i - 1] - 0.5) * size.height * 0.8 * pulseScale + offsetY;
        
        // Control point for smooth transition
        final controlX = prevX + (x - prevX) * curveSmoothing;
        final controlY = prevY + (y - prevY) * curveSmoothing;
        
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }
    
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      return; // Nothing to draw
    }

    final centerY = size.height / 2;
    final width = size.width;
    
    // Calculate gradient colors based on current amplitude
    final primaryColor = _getGradientColor(currentAmplitude);
    final secondaryColor = _getGradientColor((currentAmplitude * 0.8).clamp(0.0, 1.0));
    final tertiaryColor = _getGradientColor((currentAmplitude * 0.6).clamp(0.0, 1.0));

    // Draw multiple layers (back to front)
    for (int layer = layerCount - 1; layer >= 0; layer--) {
      final layerOffset = (layerCount - 1 - layer) * 2.0; // Slight vertical offset
      final opacity = layer == 0 ? 1.0 : (layer == 1 ? 0.7 : 0.4);
      
      // Select color for this layer
      Color layerColor;
      if (layer == 0) {
        layerColor = primaryColor;
      } else if (layer == 1) {
        layerColor = secondaryColor;
      } else {
        layerColor = tertiaryColor;
      }
      
      // Generate smooth path for this layer
      final path = _generateSmoothPath(amplitudes, size, layerOffset, opacity);
      
      // Create paint with gradient
      final paint = Paint()
        ..color = layerColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer == 0 ? 2.5 : (layer == 1 ? 2.0 : 1.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      
      // Apply gradient shader along the path
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          layerColor.withOpacity(opacity * 0.6),
          layerColor.withOpacity(opacity),
          layerColor.withOpacity(opacity * 0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, width, size.height),
      );
      
      canvas.drawPath(path, paint);
    }
    
    // Draw subtle bar accents at key points
    if (amplitudes.length > 1) {
      final barPaint = Paint()
        ..color = primaryColor.withOpacity(0.25)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0
        ..isAntiAlias = true;
      
      final spacing = width / (amplitudes.length - 1);
      final pulseScale = 0.95 + (pulseValue * 0.1);
      
      // Draw bars at every 3rd point for subtle accent
      for (int i = 0; i < amplitudes.length; i += 3) {
        final amplitude = amplitudes[i].clamp(0.0, 1.0);
        final barHeight = math.max(minBarHeight, amplitude * size.height * 0.3 * pulseScale);
        final x = i * spacing;
        final y = centerY - barHeight / 2;
        
        // Draw thin vertical line
        canvas.drawRect(
          Rect.fromLTWH(x - 0.5, y, 1.0, barHeight),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.currentAmplitude != currentAmplitude ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.layerCount != layerCount;
  }
}
