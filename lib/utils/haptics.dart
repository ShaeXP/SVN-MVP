import 'package:flutter/services.dart';

class Haptics {
  static Future<void> lightTap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> mediumTap() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> success() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}


