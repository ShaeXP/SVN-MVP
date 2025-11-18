import 'package:flutter/material.dart';
import '../../../app/navigation/bottom_nav_controller.dart';
import '../../../utils/recording_permission_helper.dart';

class QuickTabsRow extends StatelessWidget {
  const QuickTabsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = BottomNavController.I;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              // Use permission helper to gate recording
              RecordingPermissionHelper.startRecordingWithPermissions(
                context: context,
                onPermissionGranted: () {
                  // Navigate to Record tab once permission is granted
                  nav.goRecord();
                },
              );
            },
            child: const Text('Record'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => nav.goLibrary(),
            child: const Text('Library'),
          ),
        ),
      ],
    );
  }
}
