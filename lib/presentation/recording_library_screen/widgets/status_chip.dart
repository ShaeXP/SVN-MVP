// lib/presentation/recording_library_screen/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../../../services/status_transition_service.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[STATUS_CHIP] Mapping status: "$status" -> "${StatusTransitionService.getStatusDisplayInfo(status).label}"');
    final statusInfo = StatusTransitionService.getStatusDisplayInfo(status);
    
    if (compact) {
      return Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusInfo.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusInfo.icon,
              size: 12,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
            Text(
              statusInfo.label,
              style: TextStyle(
                color: statusInfo.color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      avatar: Icon(
        statusInfo.icon,
        size: 16,
        color: statusInfo.color,
      ),
      label: Text(
        statusInfo.label,
        style: TextStyle(
          color: statusInfo.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: statusInfo.color.withValues(alpha: 0.1),
      side: BorderSide(
        color: statusInfo.color.withValues(alpha: 0.3),
      ),
    );
  }
}
