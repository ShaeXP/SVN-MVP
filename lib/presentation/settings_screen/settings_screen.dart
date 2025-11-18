import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'controller/settings_controller.dart';
import 'package:lashae_s_application/ui/visuals/glass_card.dart';
import '../../ui/app_spacing.dart';
import '../../utils/nav_utils.dart';
import 'widgets/privacy_card.dart';
import '../../services/account_service.dart';
import 'widgets/animation_settings_card.dart';
import 'widgets/debug_section.dart';
import '../../env.dart';
import '../../ui/visuals/brand_background.dart';
import '../../ui/widgets/svn_scaffold_body.dart';
import '../../config/app_metadata.dart';
import '../../utils/link_service.dart';
import 'widgets/settings_rows.dart';
import 'package:flutter/foundation.dart';
import '../../app/routes/app_routes.dart';
import '../../domain/summaries/summary_style.dart';
import '../../theme/app_text_styles.dart';
import '../../debug/metrics_tracker.dart';

const double _kSettingsTopSpacing = 15.0;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    final basePadding = AppSpacing.base(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Builder(
          builder: (context) => Text(
            'Settings',
            style: AppTextStyles.screenTitle(context).copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        automaticallyImplyLeading: false, // Root tab: no back/home chevron
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
              child: SVNScaffoldBody(
                banner: null,
                padding: EdgeInsets.fromLTRB(
                  basePadding,
                  _kSettingsTopSpacing,
                  basePadding,
                  basePadding * 1.5,
                ),
                onRefresh: c.refreshMetrics,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AccountCard(),
                    AppSpacing.v(context, 0.75),
                    const _FeaturesAvailableCard(),
                    // Audio & AI card removed for v1
                    AppSpacing.v(context, 0.75),
                    const _SummaryStyleCard(),
                    AppSpacing.v(context, 0.5),
                    const _DeliverySection(),
                    AppSpacing.v(context, 0.5),
                    const PrivacyCard(),
                    AppSpacing.v(context, 0.75),
                    if (kDebugMode) ...[
                      AppSpacing.v(context, 0.5),
                      const _AdvancedExperimentsCard(),
                      AppSpacing.v(context, 0.75),
                    ],
                    const _DangerZoneCard(),
                    AppSpacing.v(context, 0.75),
                    const _AboutSupportSection(),
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

// Account Card
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    final accountService = AccountService();
    
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.v(context, 0.5),
          Obx(() => _KV(label: 'Email', value: c.accountEmail.value.isEmpty ? 'Not signed in' : c.accountEmail.value)),
          Obx(() => _KV(label: 'Plan', value: c.accountPlan.value)),
          AppSpacing.v(context, 0.5),
          Text(
            'Your recordings and summaries are stored securely in your account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.v(context, 1),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await accountService.requestDataExport();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Export requested' : 'Export request failed'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export data'),
                ),
              ),
              AppSpacing.h(context, 0.5),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Request Account Deletion'),
                        content: const Text('This will request deletion of your account. Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Request')),
                        ],
                      ),
                    ) ?? false;
                    if (!confirmed) return;
                    
                    final success = await accountService.requestAccountDeletion();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Deletion requested' : 'Deletion request failed'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Request deletion'),
                ),
              ),
              AppSpacing.h(context, 0.5),
              TextButton(
                onPressed: () => accountService.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Feature Status Card
class _FeaturesAvailableCard extends StatelessWidget {
  const _FeaturesAvailableCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Features available', style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.v(context, 0.75),
          _FeatureItem(
            icon: Icons.auto_awesome,
            title: 'Smart summaries',
            status: '✅',
            description: 'AI-generated notes from your recordings.',
          ),
          _FeatureItem(
            icon: Icons.chat_bubble_outline,
            title: 'Ask this note',
            status: '✅',
            description: 'Ask questions about a recording and get answers pulled from the note.',
          ),
          _FeatureItem(
            icon: Icons.search,
            title: 'Searchable workspace',
            status: '✅',
            description: 'Search across titles, summaries, and action items in your library.',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.status,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.35),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          AppSpacing.h(context, 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    AppSpacing.h(context, 0.5),
                    Text(status, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Metrics skeleton for loading state
class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(7, (index) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.35),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            AppSpacing.h(context, 0.5),
            Container(
              width: 40,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// Metric row for displaying key-value pairs
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.35),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              label, 
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          AppSpacing.h(context, 0.5),
          Text(
            value, 
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// Audio & AI Section
class _AudioAiSection extends StatelessWidget {
  const _AudioAiSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio & AI', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Obx(() => SettingsToggleRow(
                title: 'Normalize audio levels',
                value: c.normalizeAudio.value,
                onChanged: (v) => c.setNormalizeAudio(v),
              )),
          Obx(() => SettingsToggleRow(
                title: 'Auto-trim silence',
                value: c.autoTrimSilence.value,
                onChanged: (v) => c.setAutoTrim(v),
              )),
          const Divider(height: 16),
          Obx(() => SettingsPlainRow(
                title: 'Summarization style',
                subtitle: _getStyleSubtitle(c.summarizeStyle.value),
                onTap: () => _chooseStyle(context, c),
              )),
          Obx(() => SettingsPlainRow(
                title: 'Language hint',
                subtitle: _getLanguageSubtitle(c.languageHint.value),
                onTap: () => _chooseLanguage(context, c),
              )),
        ],
      ),
    );
  }

  String _getStyleSubtitle(String style) {
    switch (style) {
      case 'concise_actions':
        return 'Concise with action items';
      case 'detailed':
        return 'Detailed with bullets';
      case 'structured':
        return 'Summary / Actions / Follow-ups';
      default:
        return 'Concise with action items';
    }
  }

  String _getLanguageSubtitle(String lang) {
    switch (lang) {
      case 'auto':
        return 'Auto-detect';
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      default:
        return 'Auto-detect';
    }
  }

  Future<void> _chooseStyle(BuildContext context, SettingsController c) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Concise with action items'),
              subtitle: const Text('Short summary + clear next steps'),
              trailing: Obx(() => c.summarizeStyle.value == 'concise_actions'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'concise_actions'),
            ),
            ListTile(
              title: const Text('Detailed'),
              subtitle: const Text('Longer, more context'),
              trailing: Obx(() => c.summarizeStyle.value == 'detailed'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'detailed'),
            ),
            ListTile(
              title: const Text('Structured'),
              subtitle: const Text('Summary / Actions / Follow-ups'),
              trailing: Obx(() => c.summarizeStyle.value == 'structured'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'structured'),
            ),
            AppSpacing.v(_, 0.75),
          ],
        ),
      ),
    );
    if (chosen != null) await c.setSummarizeStyle(chosen);
  }

  Future<void> _chooseLanguage(BuildContext context, SettingsController c) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Auto-detect'),
              subtitle: const Text('Automatically detect language'),
              trailing: Obx(() => c.languageHint.value == 'auto'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'auto'),
            ),
            ListTile(
              title: const Text('English'),
              subtitle: const Text('English (en)'),
              trailing: Obx(() => c.languageHint.value == 'en'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'en'),
            ),
            ListTile(
              title: const Text('Spanish'),
              subtitle: const Text('Spanish (es)'),
              trailing: Obx(() => c.languageHint.value == 'es'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'es'),
            ),
            ListTile(
              title: const Text('French'),
              subtitle: const Text('French (fr)'),
              trailing: Obx(() => c.languageHint.value == 'fr'
                ? const Icon(Icons.check) : const SizedBox.shrink()),
              onTap: () => Navigator.pop(_, 'fr'),
            ),
            AppSpacing.v(_, 0.75),
          ],
        ),
      ),
    );
    if (chosen != null) await c.setLanguageHint(chosen);
  }
}

// Summary Style selection card
class _SummaryStyleCard extends StatelessWidget {
  const _SummaryStyleCard();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default summary style', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Obx(() => SettingsPlainRow(
                title: 'Default summary style',
                subtitle: summaryStyleLabelFromKey(c.summarizeStyle.value),
                onTap: () => _chooseStyle(context, c),
              )),
        ],
      ),
    );
  }

  Future<void> _chooseStyle(BuildContext context, SettingsController c) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: const VisualDensity(vertical: -2),
                title: Builder(
                  builder: (context) => Text('Quick Recap + Action Items', style: AppTextStyles.summaryOption(context)),
                ),
                trailing: Obx(() => c.summarizeStyle.value == 'quick_recap'
                    ? const Icon(Icons.check)
                    : const SizedBox.shrink()),
                onTap: () => Navigator.pop(_, 'quick_recap'),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: const VisualDensity(vertical: -2),
                title: Builder(
                  builder: (context) => Text('Organized by Topic', style: AppTextStyles.summaryOption(context)),
                ),
                trailing: Obx(() => c.summarizeStyle.value == 'organized_by_topic'
                    ? const Icon(Icons.check)
                    : const SizedBox.shrink()),
                onTap: () => Navigator.pop(_, 'organized_by_topic'),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: const VisualDensity(vertical: -2),
                title: Builder(
                  builder: (context) => Text('Decisions & Next Steps', style: AppTextStyles.summaryOption(context)),
                ),
                trailing: Obx(() => c.summarizeStyle.value == 'decisions_next_steps'
                    ? const Icon(Icons.check)
                    : const SizedBox.shrink()),
                onTap: () => Navigator.pop(_, 'decisions_next_steps'),
              ),
            ),
            AppSpacing.v(_, 0.75),
          ],
        ),
      ),
    );
    if (chosen != null) await c.setSummarizeStyle(chosen);
  }
}

// Single Reset Button
class _ResetToDefaultsButton extends StatelessWidget {
      const _ResetToDefaultsButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
        key: const Key('settings_reset_to_defaults'),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Reset to defaults?'),
              content: const Text('This will restore Home layout, app preferences, and defaults. Your recordings are safe.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(_, true), child: const Text('Reset')),
              ],
            ),
          ) ?? false;
          if (!ok) return;

          final c = Get.find<SettingsController>();
          await c.resetToDefaults();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings reset to defaults')),
            );
          }
        },
        child: const Text('Reset to defaults'),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: EdgeInsets.all(AppSpacing.base(context)),
      child: child,
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.base(context) * 0.35),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              label, 
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          AppSpacing.h(context, 0.5),
          Text(
            value, 
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// Helpers moved to widgets/settings_rows.dart

class _DeliverySection extends StatelessWidget {
  const _DeliverySection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery & notifications',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Obx(() => SettingsToggleRow(
                title: 'Auto-send email with summary',
                subtitle: 'Get notes in your inbox automatically.',
                value: c.autoSendEmail.value,
                onChanged: c.setAutoSendEmail,
              )),
        ],
      ),
    );
  }
}

class _AdvancedExperimentsCard extends StatelessWidget {
  const _AdvancedExperimentsCard();
 
   @override
   Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced & experiments', style: theme.textTheme.titleLarge),
          AppSpacing.v(context, 0.5),
          Text('Animations',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          AppSpacing.v(context, 0.25),
          const AnimationSettingsCard(),
          AppSpacing.v(context, 0.5),
          Text('Experiments',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          AppSpacing.v(context, 0.25),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish de-identified samples (public)'),
                subtitle: const Text(
                  'Exports de-identified samples for sharing. Off by default.',
                ),
                value: c.publishRedactedSamples.value,
                onChanged: c.setPublishSamples,
              )),
          AppSpacing.v(context, 0.5),
          Text('Upcoming features',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
          AppSpacing.v(context, 0.25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security,
                  color: theme.colorScheme.primary, size: 18),
              AppSpacing.h(context, 0.5),
              Expanded(
                child: Text(
                  Env.redactionEnabled
                      ? 'Redaction available now'
                      : 'Redaction shipping next build',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.v(context, 0.5),
          const DebugSection(),
          if (kDebugMode) ...[
            AppSpacing.v(context, 0.5),
            const _DebugMetricsSection(),
          ],
        ],
      ),
    );
  }
}

// Debug metrics section (debug only)
class _DebugMetricsSection extends StatelessWidget {
  const _DebugMetricsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debug metrics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        AppSpacing.v(context, 0.25),
        InkWell(
          onTap: () {
            final tracker = MetricsTracker.I;
            final summary = tracker.buildSummary();
            final json = tracker.toPrettyJson();
            final theme = Theme.of(context);

            String ms(int? v) => v == null ? '-' : '${v} ms';
            String msAvg(double? v) => v == null ? '-' : '${v.toStringAsFixed(1)} ms';

            Get.bottomSheet(
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Debug metrics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Data since last "Clear debug metrics".',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Upload stats
                        Text(
                          'Uploads',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Count: ${summary.uploadCount}'),
                        Text('Min:   ${ms(summary.uploadMinMs)}'),
                        Text('Avg:   ${msAvg(summary.uploadAvgMs)}'),
                        Text('Max:   ${ms(summary.uploadMaxMs)}'),
                        const SizedBox(height: 16),

                        // Pipeline stats
                        Text(
                          'Pipelines',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Count: ${summary.pipelineCount}'),
                        Text('Min:   ${ms(summary.pipelineMinMs)}'),
                        Text('Avg:   ${msAvg(summary.pipelineAvgMs)}'),
                        Text('Max:   ${ms(summary.pipelineMaxMs)}'),
                        const SizedBox(height: 16),

                        // Copy JSON button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy raw JSON'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: json));
                              Get.back(); // Close bottom sheet
                              Get.snackbar(
                                'Metrics copied',
                                'Debug metrics JSON is on your clipboard.',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              isScrollControlled: true,
            );
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bar_chart),
            title: const Text('Show debug metrics'),
            subtitle: const Text('View upload & pipeline timing stats'),
            onTap: null, // Disable ListTile's default onTap
          ),
        ),
        InkWell(
          onTap: () {
            MetricsTracker.I.clear();
            Get.snackbar(
              'Metrics cleared',
              'In-memory debug metrics have been reset.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear debug metrics'),
            onTap: null, // Disable ListTile's default onTap
          ),
        ),
      ],
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger zone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  )),
          AppSpacing.v(context, 0.5),
          const _ResetToDefaultsButton(),
        ],
      ),
    );
  }
}

class _PipelineMetricsSection extends StatelessWidget {
  const _PipelineMetricsSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipeline metrics (last 168h)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        AppSpacing.v(context, 0.5),
        Obx(() {
          if (c.metricsLoading.value) {
            return const _MetricsSkeleton();
          }
          if (c.metricsError.value != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load metrics',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                AppSpacing.v(context, 0.5),
                FilledButton.tonal(
                  onPressed: c.refreshMetrics,
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          final m = c.metrics.value;
          String fmt(String key, {String fallback = '—'}) =>
              (m?[key] == null) ? fallback : m![key].toString();

          return Column(
            children: [
              _MetricRow(
                  label: 'Success rate',
                  value: fmt('success_rate', fallback: '—')),
              _MetricRow(label: 'Total runs', value: fmt('total_runs')),
              _MetricRow(label: 'Deduped (409)', value: fmt('deduped')),
              _MetricRow(
                  label: 'TTFN p50 / p90',
                  value: '${fmt('ttfn_p50')} / ${fmt('ttfn_p90')}'),
              _MetricRow(label: 'Transcribe avg', value: fmt('transcribe_avg')),
              _MetricRow(label: 'Summarize avg', value: fmt('summarize_avg')),
              _MetricRow(label: 'Email avg', value: fmt('email_avg')),
            ],
          );
        }),
      ],
    );
  }
}

// About & Support Section
class _AboutSupportSection extends StatelessWidget {
  const _AboutSupportSection();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About & Support',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.v(context, 1),
          // App icon + name + tagline
          Row(
            children: [
              // App icon placeholder (using a simple icon for now)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              AppSpacing.h(context, 0.75),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppMetadata.appName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.v(context, 0.25),
                    Text(
                      AppMetadata.tagline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.v(context, 0.75),
          // Version info
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final info = snapshot.data!;
              return Text(
                'Version ${info.version} (Build ${info.buildNumber})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              );
            },
          ),
          AppSpacing.v(context, 1),
          const Divider(),
          AppSpacing.v(context, 0.5),
          // How SmartVoiceNotes works link
          _LinkTile(
            icon: Icons.info_outline,
            label: 'How SmartVoiceNotes works',
            onTap: () {
              Get.toNamed(Routes.howItWorks);
            },
          ),
          // Privacy Policy link
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () async {
              final opened = await LinkService.openUrl(AppMetadata.privacyPolicyUrl);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open URL')),
                );
              }
            },
          ),
          // Terms of Service link
          _LinkTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () async {
              final opened = await LinkService.openUrl(AppMetadata.termsOfServiceUrl);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open URL')),
                );
              }
            },
          ),
          // Contact Support link
          _LinkTile(
            icon: Icons.email_outlined,
            label: 'Contact Support',
            onTap: () async {
              final opened = await LinkService.openEmail(
                to: AppMetadata.supportEmail,
                subject: 'SmartVoiceNotes Support',
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No email app is installed on this device.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Link tile widget for consistent styling
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.base(context) * 0.5,
          horizontal: AppSpacing.base(context) * 0.25,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppSpacing.h(context, 0.75),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}