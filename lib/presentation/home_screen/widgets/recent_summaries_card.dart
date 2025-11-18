import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/summary_navigation.dart';
import '../../../ui/widgets/recording_card.dart';
import '../../../ui/app_spacing.dart';
import '../controller/home_controller.dart';
import '../../../presentation/library/library_controller.dart';
import '../../../app/navigation/bottom_nav_controller.dart';

class RecentSummariesCard extends StatelessWidget {
  const RecentSummariesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (controller.recentSummaries.isEmpty) {
        debugPrint('[HomeEmptyState] no recent summaries, showing CTA');
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.base(context) * 0.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No summaries yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: AppSpacing.base(context) * 0.25),
              Text(
                'Record a note to see it here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              SizedBox(height: AppSpacing.base(context) * 0.5),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: () {
                    BottomNavController.I.goTab(1);
                  },
                  child: const Text('Record a note'),
                ),
              ),
            ],
          ),
        );
      }

      // Match Library screen's exact card layout and spacing
      final summaries = controller.recentSummaries.take(5).toList();
      final cards = <Widget>[];
      
      for (int i = 0; i < summaries.length; i++) {
        final m = summaries[i];
        final rid = (m['recording_id'] ?? '').toString();
        final title = (m['title'] ?? 'Untitled').toString();
        final sum = (m['summary'] ?? '').toString();
        
        // Convert summary map to RecordingItem for RecordingCard
        final item = RecordingItem(
          id: rid,
          title: title,
          status: 'ready', // Recent summaries are always ready
          durationSec: null, // Not available in summary data
          preview: sum,
        );
        
        // Recent summaries are always ready, so they can be deleted
        cards.add(
          RecordingCard(
            item: item,
            // Home should feel lighter: use compact previews here
            compact: true,
            showDeleteButton: true,
            onDelete: () => _confirmDeleteRecording(context, controller, rid),
            onTap: () {
              if (rid.isEmpty) {
                Get.snackbar('Error', 'Missing recording ID');
                return;
              }
              openRecordingSummary(recordingId: rid, summaryId: title);
            },
          ),
        );
        
        // Add spacing between cards matching Library screen (except after last card)
        if (i < summaries.length - 1) {
          cards.add(SizedBox(height: AppSpacing.md));
        }
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      );
    });
  }

  /// Show delete confirmation dialog
  static Future<void> _confirmDeleteRecording(
    BuildContext context,
    HomeController controller,
    String recordingId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete summary?'),
        content: const Text(
          'This will remove this recording and its summary from your library. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await controller.deleteRecording(recordingId);
        // Success: card already removed optimistically, just show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Error: item was restored by controller, show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
