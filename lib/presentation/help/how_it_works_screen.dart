import 'package:flutter/material.dart';
import '../../ui/visuals/brand_background.dart';
import '../../ui/visuals/glass_card.dart';
import '../../ui/app_spacing.dart';
import '../../config/app_metadata.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basePadding = AppSpacing.base(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('How SmartVoiceNotes works'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BrandGradientBackground()),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: basePadding,
                  vertical: basePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro
                    Text(
                      '${AppMetadata.appName} turns your recordings into clean, structured notes you can skim in seconds.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    AppSpacing.v(context, 1.5),

                    // 3-step flow card
                    const _HowItWorksStepsCard(),

                    AppSpacing.v(context, 1.5),

                    // Sample summary
                    const _SampleSummaryCard(),

                    AppSpacing.v(context, 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStepsCard extends StatelessWidget {
  const _HowItWorksStepsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: 16,
      padding: EdgeInsets.all(AppSpacing.base(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The 3-step flow',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.v(context, 1),
          const _StepRow(
            index: 1,
            title: 'Record or upload',
            body: 'Capture a quick voice note, or upload an existing recording from your device.',
          ),
          AppSpacing.v(context, 1),
          const _StepRow(
            index: 2,
            title: 'We transcribe & summarize',
            body: 'SmartVoiceNotes processes the audio, turning it into a transcript and structured summary.',
          ),
          AppSpacing.v(context, 1),
          const _StepRow(
            index: 3,
            title: 'Review in your Library',
            body: 'Open the summary, skim the key points, add your own notes, and send it by email if you need to share.',
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String title;
  final String body;

  const _StepRow({
    required this.index,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            index.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppSpacing.h(context, 0.75),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpacing.v(context, 0.25),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleSummaryCard extends StatelessWidget {
  const _SampleSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: 16,
      padding: EdgeInsets.all(AppSpacing.base(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What your notes look like',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.v(context, 0.75),
          Text(
            '${AppMetadata.appName} generates a structured page with:',
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.v(context, 0.75),
          Text(
            '• A short, readable summary\n'
            '• Bullet-point key takeaways\n'
            '• A place for your own raw notes\n'
            '• A status chip so you know when processing is done',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

