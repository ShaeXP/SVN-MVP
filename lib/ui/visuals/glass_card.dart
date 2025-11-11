import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated; // optional soft shadow

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0x40000000) : const Color(0xA6FFFFFF), // ~25% black / ~65% white
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: elevated
            ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8))]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
