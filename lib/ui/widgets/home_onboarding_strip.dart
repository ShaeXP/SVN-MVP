import 'package:flutter/material.dart';
import '../app_spacing.dart';
import '../visuals/glass_card.dart';

/// Dismissible onboarding strip for the Home screen
/// Explains the 3-step flow of the app
class HomeOnboardingStrip extends StatelessWidget {
  final VoidCallback onDismiss;

  const HomeOnboardingStrip({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GlassCard(
      radius: 16,
      padding: EdgeInsets.all(AppSpacing.base(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'How SmartVoiceNotes works',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          AppSpacing.v(context, 0.75),
          Text(
            '1. Record a note\n'
            '2. We transcribe & summarize\n'
            '3. Find it in your Library or email',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          AppSpacing.v(context, 0.75),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

