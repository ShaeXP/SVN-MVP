import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/navigation/bottom_nav_controller.dart';
import '../controller/home_controller.dart';

class ProcessingSummaryCard extends StatelessWidget {
  const ProcessingSummaryCard({super.key});

  void _goToLibrary() {
    // Navigate to Library tab (index 2) using BottomNavController
    final nav = BottomNavController.I;
    nav.goTab(2); // Library tab
  }

  @override
  Widget build(BuildContext context) {
    final hc = Get.find<HomeController>();
    return Obx(() {
      final count = hc.inProgressCount.value;
      if (count <= 0) return const SizedBox.shrink();

      return Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _goToLibrary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.autorenew),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count notes are processing in the background.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _goToLibrary,
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
