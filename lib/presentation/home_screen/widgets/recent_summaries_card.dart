import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/summary_navigation.dart';
import '../controller/home_controller.dart';

class RecentSummariesCard extends StatelessWidget {
  const RecentSummariesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (controller.recentSummaries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Column(
            children: controller.recentSummaries.take(5).map((m) {
              final rid = (m['recording_id'] ?? '').toString();
              final title = (m['title'] ?? 'Untitled').toString();
              final sum = (m['summary'] ?? '').toString();
              final tags = (m['tags'] ?? []) as List<dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(sum, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, 
                      runSpacing: 6,
                      children: tags.take(4).map((t) => Chip(label: Text(t.toString()))).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          if (rid.isEmpty) {
                            Get.snackbar('Error', 'Missing recording ID');
                            return;
                          }
                          // Use standardized navigation helper with fallback
                          openRecordingSummary(recordingId: rid, summaryId: title);
                        }, 
                        child: const Text('Open summary')
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
