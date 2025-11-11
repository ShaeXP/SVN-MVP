import 'dart:ui';
import 'package:flutter/material.dart';

class GlassDock extends StatelessWidget {
  final Widget child;
  const GlassDock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), // inset from edges
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x33000000)    // ~20% black
                  : const Color(0x99FFFFFF),    // ~60% white (less harsh)
              border: Border.all(color: const Color(0x22FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
