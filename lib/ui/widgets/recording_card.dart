import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../visuals/glass_card.dart';
import '../app_spacing.dart';
import '../../presentation/recording_library_screen/widgets/status_chip.dart';
import '../../presentation/library/library_controller.dart';
import '../../utils/summary_navigation.dart';

/// Shared recording card widget for Home and Library screens
class RecordingCard extends StatelessWidget {
  const RecordingCard({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
    this.showExportButton = false,
    this.onExport,
    this.onDelete,
    this.showDeleteButton = false,
  });

  final RecordingItem item;
  final VoidCallback? onTap;
  final bool compact;
  final bool showExportButton;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      // Check if this recording is recently created (only in Library context)
      final controller = Get.isRegistered<LibraryController>() 
          ? Get.find<LibraryController>() 
          : null;
      final isNew = controller?.recentlyCreatedRecordingId.value == item.id;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isNew
              ? Colors.white.withOpacity(0.10) // subtle highlight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: GlassCard(
          radius: 16,
          elevated: true,
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap ?? () {
                openRecordingSummary(recordingId: item.id);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title + optional trailing actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.title?.isNotEmpty == true
                              ? item.title!
                              : 'Untitled recording',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.greenAccent.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDeleteButton && onDelete != null)
                            _ActionIconButton(
                              icon: Icons.delete_outline,
                              color: Colors.red.shade400,
                              onTap: onDelete,
                            ),
                          if (showExportButton && onExport != null) ...[
                            const SizedBox(width: 6),
                            _ActionIconButton(
                              icon: Icons.share_outlined,
                              color: colorScheme.onSurfaceVariant,
                              onTap: onExport,
                            ),
                          ],
                          const SizedBox(width: 6),
                          _ActionIconButton(
                            icon: Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                            onTap: onTap ?? () {
                              openRecordingSummary(recordingId: item.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

              // Preview text (if available)
              if (item.preview != null && item.preview!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  item.preview!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

                  // Bottom row: Status chip + duration/timestamp
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatusChip(status: item.status),
                      Text(
                        _formatDuration(item.durationSec),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      highlightShape: BoxShape.circle,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

