import 'package:flutter/material.dart';
import '../../services/permission_service.dart';
import '../app_spacing.dart';

/// Widget shown when microphone permission is denied
/// Offers to open settings to enable permission
class MicPermissionBlocked extends StatelessWidget {
  final VoidCallback? onDismiss;

  const MicPermissionBlocked({
    super.key,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final permissionService = PermissionService.instance;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_off,
              size: 64,
              color: colorScheme.error,
            ),
            AppSpacing.v(context, 1),
            Text(
              'Microphone access is turned off',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.v(context, 0.75),
            Text(
              'SmartVoiceNotes can\'t record without mic access. You can enable it in your device settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.v(context, 1.5),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    child: const Text('Maybe later'),
                  ),
                ),
                AppSpacing.h(context, 0.5),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await permissionService.openAppSettings();
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show the blocked dialog
  static Future<void> show(BuildContext context, {VoidCallback? onDismiss}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MicPermissionBlocked(
        onDismiss: () {
          Navigator.of(context).pop();
          onDismiss?.call();
        },
      ),
    );
  }
}

