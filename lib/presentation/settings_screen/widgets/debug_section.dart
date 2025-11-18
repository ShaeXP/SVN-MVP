import 'package:flutter/material.dart';
import '../../../ui/app_spacing.dart';

class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.bug_report_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
        AppSpacing.h(context, 0.5),
        Expanded(
          child: Text(
            'Debug settings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
