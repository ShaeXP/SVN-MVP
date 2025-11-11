import 'package:flutter/material.dart';
import '../../../app/navigation/bottom_nav_controller.dart';

class QuickTabsRow extends StatelessWidget {
  const QuickTabsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = BottomNavController.I;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => nav.goRecord(),
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
