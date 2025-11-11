import 'package:flutter/material.dart';
import '../../../ui/app_spacing.dart';

class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bug_report_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            AppSpacing.h(context, 0.5),
            Text(
              'Debug settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        AppSpacing.v(context, 0.5),
        Text(
          'Debug settings will be added here',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
