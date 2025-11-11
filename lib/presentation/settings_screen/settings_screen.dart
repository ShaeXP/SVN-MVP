import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: const Text('Settings'),
        leading: IconButton(
          key: const Key('nav_home_from_settings'),
          tooltip: 'Home',
          icon: const Icon(Icons.home_outlined),
          onPressed: NavUtils.goHome,
        ),
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
                    AppSpacing.v(context, 1),
                    const _FeaturesAvailableCard(),
                    AppSpacing.v(context, 1),
                    const _AudioAiSection(),
                    AppSpacing.v(context, 1),
                    const _DeliverySection(),
                    AppSpacing.v(context, 1),
                    const PrivacyCard(),
                    AppSpacing.v(context, 1),
                    const _DeveloperAdvancedCard(),
                    AppSpacing.v(context, 1.5),
                    const _DangerZoneCard(),
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
                child: TextButton.icon(
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
            ],
          ),
          AppSpacing.v(context, 0.5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => accountService.signOut(),
              child: const Text('Sign out'),
            ),
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
            icon: Icons.transcribe,
            title: 'Transcription',
            status: '✅',
            description: 'AI-powered speech-to-text',
          ),
          _FeatureItem(
            icon: Icons.summarize,
            title: 'Summarization',
            status: '✅',
            description: 'AI-generated meeting summaries',
          ),
          _FeatureItem(
            icon: Icons.email,
            title: 'Email export',
            status: '✅',
            description: 'Send summaries via email',
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
    
    return _Card(
      child: Column(
        children: [
          Text('Audio & AI', style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.v(context, 0.5),
          Obx(() => SwitchListTile(
            title: const Text('Normalize audio levels'),
            value: c.normalizeAudio.value,
            onChanged: (value) => c.setNormalizeAudio(value),
          )),
          Obx(() => SwitchListTile(
            title: const Text('Auto-trim silence'),
            value: c.autoTrimSilence.value,
            onChanged: (value) => c.setAutoTrim(value),
          )),
          const Divider(),
          Obx(() => ListTile(
            title: const Text('Summarization style'),
            subtitle: Text(_getStyleSubtitle(c.summarizeStyle.value)),
            onTap: () => _chooseStyle(context, c),
          )),
          Obx(() => ListTile(
            title: const Text('Language hint'),
            subtitle: Text(_getLanguageSubtitle(c.languageHint.value)),
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

// Single Reset Button
class _ResetToDefaultsButton extends StatelessWidget {
  const _ResetToDefaultsButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonal(
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
      ),
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

class _DeliverySection extends StatelessWidget {
  const _DeliverySection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery & notifications',
              style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.v(context, 0.5),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-send email with summary'),
                value: c.autoSendEmail.value,
                onChanged: c.setAutoSendEmail,
              )),
        ],
      ),
    );
  }
}

class _DeveloperAdvancedCard extends StatelessWidget {
  const _DeveloperAdvancedCard();
 
   @override
   Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Developer / Advanced', style: theme.textTheme.titleLarge),
          AppSpacing.v(context, 0.75),
          const _PipelineMetricsSection(),
          AppSpacing.v(context, 1),
          const AnimationSettingsCard(),
          AppSpacing.v(context, 1),
          Text('Experiments',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish de-identified samples (public)'),
                subtitle: const Text(
                  'Exports de-identified PDF samples for sharing. Your originals stay private.',
                ),
                value: c.publishRedactedSamples.value,
                onChanged: c.setPublishSamples,
              )),
          AppSpacing.v(context, 1),
          Text('Upcoming features',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          AppSpacing.v(context, 0.5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security,
                  color: theme.colorScheme.primary, size: 20),
              AppSpacing.h(context, 0.75),
              Expanded(
                child: Text(
                  Env.redactionEnabled
                      ? 'Redaction available now'
                      : 'Redaction shipping next build',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          AppSpacing.v(context, 1),
          const DebugSection(),
        ],
      ),
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
          AppSpacing.v(context, 0.75),
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