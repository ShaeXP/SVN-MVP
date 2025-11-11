// lib/ui/widgets/card_surface.dart
import 'package:flutter/material.dart';
import '../theme/svn_theme.dart';

class CardSurface extends StatelessWidget {
  const CardSurface({super.key, required this.child, this.padding = const EdgeInsets.all(SVNTheme.cardPad)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SVNTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(SVNTheme.radius),
        border: Border.all(color: SVNTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}

