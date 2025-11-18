import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/settings_controller.dart';
import '../../../env.dart';
import '../../../ui/visuals/glass_card.dart';
import '../../../ui/app_spacing.dart';
import 'settings_rows.dart';

class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Privacy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SettingsToggleRow(
            title: 'Analytics & usage reports',
            subtitle: 'Optional, anonymized usage stats.',
            value: c.analyticsOptIn.value,
            onChanged: c.setAnalytics,
          ),
          SettingsToggleRow(
            title: 'Crash diagnostics',
            subtitle: 'Help improve reliability (never includes your audio).',
            value: c.crashOptIn.value,
            onChanged: c.setCrash,
          ),
          if (!Env.demoMode)
            SettingsToggleRow(
              title: 'Redact personal info in transcripts',
              value: c.redactPII.value,
              onChanged: c.setRedact,
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            title: const Text('Data retention'),
            subtitle: Text(
              'Keeps summaries for ${_labelForRetention(c.dataRetentionDays.value)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseRetention(context, c),
          ),
        ],
      )),
    );
  }

  String _labelForRetention(int days) {
    switch (days) {
      case 0: return 'Keep forever';
      case 7: return '7 days';
      case 30: return '30 days';
      case 90: return '90 days';
      default: return '$days days';
    }
  }

  Future<void> _chooseRetention(BuildContext context, SettingsController c) async {
    final v = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: const Text('7 days'),   onTap: () => Navigator.pop(_, 7)),
          ListTile(title: const Text('30 days'),  onTap: () => Navigator.pop(_, 30)),
          ListTile(title: const Text('90 days'),  onTap: () => Navigator.pop(_, 90)),
          ListTile(title: const Text('Keep forever'), onTap: () => Navigator.pop(_, 0)),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (v != null) await c.setRetention(v);
  }
}
