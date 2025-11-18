import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  // Simple spacing constants for consistent UI
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static double base(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 12;
    if (width <= 420) return 16;
    if (width <= 540) return 20;
    return 24;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final b = base(context);
    return EdgeInsets.symmetric(horizontal: b, vertical: b);
  }

  static EdgeInsets sectionPadding(BuildContext context) {
    final b = base(context);
    return EdgeInsets.all(b);
  }

  static SizedBox v(BuildContext context, [double mult = 1]) {
    return SizedBox(height: base(context) * mult);
  }

  static SizedBox h(BuildContext context, [double mult = 1]) {
    return SizedBox(width: base(context) * mult);
  }
}
