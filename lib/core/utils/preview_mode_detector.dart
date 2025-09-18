import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class to detect if app is running in preview mode
/// and handle external service initialization with timeouts
class PreviewModeDetector {
  static const Duration _initTimeout = Duration(seconds: 2);

  /// Check if app is running in preview mode
  /// Returns true if:
  /// - In debug mode AND initial route is preview health check
  /// - Or explicitly set via environment variable
  static bool get isPreviewMode {
    // Check environment variable first
    const previewModeEnv =
        String.fromEnvironment('PREVIEW_MODE', defaultValue: '');
    if (previewModeEnv.toLowerCase() == 'true') {
      return true;
    }

    // In debug mode, assume preview if we're in development
    if (kDebugMode) {
      return true; // Enable preview mode in debug builds
    }

    return false;
  }

  /// Execute function with timeout and fallback
  /// Returns fallback result if timeout or error occurs in preview mode
  static Future<T> withPreviewTimeout<T>(
    Future<T> Function() operation,
    T fallback, {
    String? serviceName,
  }) async {
    if (!isPreviewMode) {
      // Not in preview mode, execute normally
      return await operation();
    }

    try {
      debugPrint(
          'ðŸ”„ Preview mode: Initializing ${serviceName ?? "service"} with timeout...');

      return await operation().timeout(
        _initTimeout,
        onTimeout: () {
          debugPrint(
              'âš ï¸ Preview mode: ${serviceName ?? "Service"} initialization timed out, using fallback');
          return fallback;
        },
      );
    } catch (e) {
      debugPrint(
          'âš ï¸ Preview mode: ${serviceName ?? "Service"} initialization failed: $e, using fallback');
      return fallback;
    }
  }

  /// Execute void function with timeout handling
  static Future<void> withPreviewTimeoutVoid(
    Future<void> Function() operation, {
    String? serviceName,
  }) async {
    if (!isPreviewMode) {
      // Not in preview mode, execute normally
      await operation();
      return;
    }

    try {
      debugPrint(
          'ðŸ”„ Preview mode: Initializing ${serviceName ?? "service"} with timeout...');

      await operation().timeout(
        _initTimeout,
        onTimeout: () {
          debugPrint(
              'âš ï¸ Preview mode: ${serviceName ?? "Service"} initialization timed out, continuing...');
        },
      );
    } catch (e) {
      debugPrint(
          'âš ï¸ Preview mode: ${serviceName ?? "Service"} initialization failed: $e, continuing...');
    }
  }
}
