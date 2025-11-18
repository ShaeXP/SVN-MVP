import 'package:flutter/material.dart';
import '../../utils/link_service.dart';
import '../../config/app_metadata.dart';
import '../app_spacing.dart';

/// Error panel shown when a recording has failed to process
class RecordingErrorPanel extends StatelessWidget {
  const RecordingErrorPanel({
    super.key,
    required this.recordingId,
    this.onRetry,
  });

  final String recordingId;
  final VoidCallback? onRetry;

  Future<void> _contactSupport() async {
    await LinkService.openEmail(
      to: AppMetadata.supportEmail,
      subject: 'SmartVoiceNotes – recording failed to process',
      body: 'Recording ID: $recordingId\n\n'
          'This recording failed to process. Please help investigate.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.base(context)),
      padding: EdgeInsets.all(AppSpacing.base(context)),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.onErrorContainer,
                size: 24,
              ),
              SizedBox(width: AppSpacing.base(context) * 0.5),
              Expanded(
                child: Text(
                  'We couldn\'t finish this summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.base(context) * 0.5),
          Text(
            'This recording didn\'t finish processing. You can try again or contact support if it keeps happening.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.base(context)),
          Row(
            children: [
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                ),
              SizedBox(width: AppSpacing.base(context) * 0.5),
              TextButton(
                onPressed: _contactSupport,
                child: const Text('Contact support'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

