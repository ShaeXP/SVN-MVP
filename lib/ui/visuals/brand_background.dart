import 'package:flutter/material.dart';

class BrandGradientBackground extends StatelessWidget {
  final bool withGlows;
  const BrandGradientBackground({super.key, this.withGlows = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget glows = Stack(children: const [
      _RadialGlow(offset: Offset(0.75, -0.2), color: Color(0x66FFFFFF)),
      _RadialGlow(offset: Offset(-0.4, 0.9), color: Color(0x3344D7FF)),
    ]);

    return DecoratedBox(
      position: DecorationPosition.background,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.8),
          end: const Alignment(1.0, 0.9),
          colors: isDark
              ? const [Color(0xFF1C1730), Color(0xFF0E2333)]
              : const [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF22D3EE)],
          stops: isDark ? const [0.0, 1.0] : const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: withGlows ? glows : const SizedBox.shrink(),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  final Offset offset;
  final Color color;
  const _RadialGlow({required this.offset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(offset.dx, offset.dy),
              radius: 0.75,
              colors: [color, color.withOpacity(0)],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }
}
