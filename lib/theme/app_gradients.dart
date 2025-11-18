import 'package:flutter/material.dart';

/// Centralized gradient definitions for the app
class AppGradients {
  AppGradients._();

  /// Main background gradient used on Home screen and splash screen
  /// Dark theme version: deep violet to ink blue
  static const mainBackground = LinearGradient(
    begin: Alignment(-1.0, -0.8),   // top-left-ish
    end: Alignment(1.0, 0.9),       // bottom-right-ish
    colors: [
      Color(0xFF1C1730),            // deep violet
      Color(0xFF0E2333),            // ink blue
    ],
    stops: [0.0, 1.0],
  );

  /// Light theme version of main background gradient
  static const mainBackgroundLight = LinearGradient(
    begin: Alignment(-1.0, -0.8),   // top-left-ish
    end: Alignment(1.0, 0.9),       // bottom-right-ish
    colors: [
      Color(0xFF8B5CF6),            // violet-500
      Color(0xFF6366F1),            // indigo-500
      Color(0xFF3B82F6),            // blue-500
      Color(0xFF22D3EE),            // cyan-400
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  /// Returns the appropriate main background gradient based on theme brightness
  static LinearGradient mainBackgroundFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? mainBackground : mainBackgroundLight;
  }
}

