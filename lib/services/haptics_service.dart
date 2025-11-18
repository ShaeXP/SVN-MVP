import 'package:flutter/services.dart';

/// Service for providing haptic feedback
class HapticsService {
  /// Light haptic tap (for subtle interactions)
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic tap (for primary actions like start/stop recording)
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Success haptic (for completion states like "Ready")
  static Future<void> success() async {
    await HapticFeedback.selectionClick();
  }
}

