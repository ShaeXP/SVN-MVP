import 'package:flutter/material.dart';
import '../app_spacing.dart';

/// Futuristic-lite shared surface used across SmartVoiceNotes pages.
class SVNCard extends StatelessWidget {
  const SVNCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 20,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0x40000000)
        : const Color(0xCCFFFFFF);
    final base = AppSpacing.base(context);
    final resolvedPadding = padding ?? EdgeInsets.all(base);
    final resolvedMargin = margin ?? EdgeInsets.only(bottom: base);

    return Container(
      margin: resolvedMargin,
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.white30,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

