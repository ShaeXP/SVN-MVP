import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/settings_controller.dart';
import '../../../env.dart';

class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Privacy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            SwitchListTile(
              title: const Text('Analytics & usage reports'),
              value: c.analyticsOptIn.value,
              onChanged: c.setAnalytics,
            ),
            SwitchListTile(
              title: const Text('Crash diagnostics'),
              value: c.crashOptIn.value,
              onChanged: c.setCrash,
            ),
            // Hide redaction toggle in demo mode
            if (!Env.demoMode)
              SwitchListTile(
                title: const Text('Redact personal info in transcripts'),
                value: c.redactPII.value,
                onChanged: c.setRedact,
              ),
            ListTile(
              title: const Text('Data retention'),
              subtitle: Text(_labelForRetention(c.dataRetentionDays.value)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _chooseRetention(context, c),
            ),
          ],
        )),
      ),
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
