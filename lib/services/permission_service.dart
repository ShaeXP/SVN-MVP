import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform;

/// Central service for handling app permissions
class PermissionService extends GetxService {
  static PermissionService get instance => Get.find<PermissionService>();

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await ph.Permission.microphone.status;
    return status.isGranted;
  }

  /// Ensure microphone permission is granted, requesting if needed
  /// Returns true if granted, false if denied or permanently denied
  Future<bool> ensureMicrophonePermission() async {
    try {
      final status = await ph.Permission.microphone.status;
      
      if (status.isGranted) {
        debugPrint('[PermissionService] Microphone permission already granted');
        return true;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('[PermissionService] Microphone permission permanently denied');
        return false;
      }

      // Request permission
      debugPrint('[PermissionService] Requesting microphone permission...');
      final newStatus = await ph.Permission.microphone.request();
      
      if (newStatus.isGranted) {
        debugPrint('[PermissionService] Microphone permission granted');
        return true;
      }

      debugPrint('[PermissionService] Microphone permission denied');
      return false;
    } catch (e) {
      debugPrint('[PermissionService] Error checking microphone permission: $e');
      return false;
    }
  }

  /// Check if permission is permanently denied (user must go to settings)
  Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await ph.Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings for user to manually enable permissions
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      debugPrint('[PermissionService] Error opening app settings: $e');
      return false;
    }
  }

  /// Ensure file access permission (if needed for uploads)
  /// On modern platforms with file picker APIs, this may just return true
  Future<bool> ensureFileAccessPermission() async {
    // On iOS and modern Android, file picker APIs don't require explicit storage permission
    // The file picker handles permissions internally
    if (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }

    // For other platforms, check storage permission if needed
    // This is a placeholder - adjust based on actual platform requirements
    try {
      final status = await ph.Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      final newStatus = await ph.Permission.storage.request();
      return newStatus.isGranted;
    } catch (e) {
      debugPrint('[PermissionService] Error checking file access permission: $e');
      // Default to true to avoid blocking uploads unnecessarily
      return true;
    }
  }
}

