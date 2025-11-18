import 'package:flutter/material.dart';
import '../app_spacing.dart';

/// Widget shown before requesting microphone permission
/// Explains why the app needs microphone access
class MicPermissionExplainer extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const MicPermissionExplainer({
    super.key,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Icons.mic,
              size: 64,
              color: colorScheme.primary,
            ),
            AppSpacing.v(context, 1),
            Text(
              'SmartVoiceNotes needs microphone access',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.v(context, 0.75),
            Text(
              'We use your mic to record your notes so we can transcribe and summarize them for you. You\'re always in control.',
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
                    onPressed: onCancel,
                    child: const Text('Not now'),
                  ),
                ),
                AppSpacing.h(context, 0.5),
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show the explainer dialog
  static Future<void> show(BuildContext context, {
    required VoidCallback onContinue,
    required VoidCallback onCancel,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MicPermissionExplainer(
        onContinue: () {
          Navigator.of(context).pop();
          onContinue();
        },
        onCancel: () {
          Navigator.of(context).pop();
          onCancel();
        },
      ),
    );
  }
}

