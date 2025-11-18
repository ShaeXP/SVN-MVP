import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../ui/widgets/mic_permission_explainer.dart';
import '../ui/widgets/mic_permission_blocked.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Shared helper for starting recording with proper permission flow
class RecordingPermissionHelper {
  /// Start recording with permission checks and user-friendly flows
  /// 
  /// This handles:
  /// 1. Checking if permission is already granted (proceed immediately)
  /// 2. Showing explainer before requesting permission (first time)
  /// 3. Requesting permission
  /// 4. Showing blocked UI if denied
  /// 5. Calling onPermissionGranted callback when ready to record
  static Future<void> startRecordingWithPermissions({
    required BuildContext context,
    required VoidCallback onPermissionGranted,
  }) async {
    final permissionService = PermissionService.instance;

    // Check if permission is already granted
    final hasPermission = await permissionService.hasMicrophonePermission();
    if (hasPermission) {
      debugPrint('[RecordingPermissionHelper] Permission already granted, proceeding');
      onPermissionGranted();
      return;
    }

    // Check if permanently denied - show blocked UI immediately
    final isPermanentlyDenied = await permissionService.isMicrophonePermissionPermanentlyDenied();
    if (isPermanentlyDenied) {
      debugPrint('[RecordingPermissionHelper] Permission permanently denied, showing blocked UI');
      await MicPermissionBlocked.show(context);
      return;
    }

    // Show explainer before requesting permission
    await MicPermissionExplainer.show(
      context,
      onContinue: () async {
        // Request permission after user taps Continue
        final granted = await permissionService.ensureMicrophonePermission();
        
        if (granted) {
          debugPrint('[RecordingPermissionHelper] Permission granted after request');
          onPermissionGranted();
        } else {
          debugPrint('[RecordingPermissionHelper] Permission denied after request, showing blocked UI');
          // Check if it's now permanently denied
          final nowPermanentlyDenied = await permissionService.isMicrophonePermissionPermanentlyDenied();
          if (nowPermanentlyDenied || context.mounted) {
            await MicPermissionBlocked.show(context);
          }
        }
      },
      onCancel: () {
        debugPrint('[RecordingPermissionHelper] User cancelled permission request');
        // User chose "Not now" - do nothing
      },
    );
  }
}

