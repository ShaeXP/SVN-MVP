import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/connectivity_service.dart';
import '../app_spacing.dart';

/// Compact banner shown at the top of the app when offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (!connectivity.isOffline.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base(context),
          vertical: AppSpacing.base(context) * 0.5,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacing.base(context) * 0.5),
            Expanded(
              child: Text(
                'Offline. Some actions will resume when you\'re back online.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

