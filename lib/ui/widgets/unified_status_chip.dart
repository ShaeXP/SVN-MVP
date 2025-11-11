import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../status/status_theme.dart';
import '../../domain/recordings/recording_status.dart';
import '../../domain/recordings/pipeline_view_state.dart';
import '../util/pipeline_step.dart';
import 'pipeline_progress.dart';

/// Unified status chip that displays recording status with native animations
/// Uses the single source of truth for status appearance
class UnifiedStatusChip extends StatelessWidget {
  final RecordingStatus status;
  final String? traceId;
  final bool showProgress;
  final VoidCallback? onRetry;

  const UnifiedStatusChip({
    super.key,
    required this.status,
    this.traceId,
    this.showProgress = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = StatusTheme.forStatus(status);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(theme.animKey),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.getChipColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.getChipBorderColor(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                theme.icon,
                key: ValueKey(theme.icon),
                size: 16,
                color: theme.getChipTextColor(context),
              ),
            ),
            const SizedBox(width: 8),
            
            // Label
            Text(
              theme.label,
              style: TextStyle(
                color: theme.getChipTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            // Progress indicator (if enabled and available)
            if (showProgress && theme.progress != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: theme.progress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.getChipTextColor(context),
                  ),
                ),
              ),
            ],
            
            // Retry button for error state
            if (status == RecordingStatus.error && onRetry != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRetry,
                child: Icon(
                  Icons.refresh,
                  size: 14,
                  color: theme.getChipTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress bar widget that shows linear progress for processing states
class UnifiedProgressBar extends StatelessWidget {
  final RecordingStatus status;
  final double? customProgress;

  const UnifiedProgressBar({
    super.key,
    required this.status,
    this.customProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = StatusTheme.forStatus(status);
    final progress = customProgress ?? theme.progress;
    
    if (progress == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: 4,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: theme.getChipColor(context),
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.getChipTextColor(context),
        ),
      ),
    );
  }
}

/// Pipeline progress banner that shows current status with animations
class UnifiedPipelineBanner extends StatelessWidget {
  final String recordingId;
  
  const UnifiedPipelineBanner({
    super.key, 
    required this.recordingId,
  });

  @override
  Widget build(BuildContext context) {
    // Check if PipelineRx exists first
    if (!Get.isRegistered<PipelineRx>(tag: 'pipe_$recordingId')) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      try {
        final rx = Get.find<PipelineRx>(tag: 'pipe_$recordingId');
        final s = rx.status.value;
        final p = rx.progress.value;
        final show = rx.hasProgress.value;
        final k = rx.animKey.value;

        return Column(
          mainAxisSize: MainAxisSize.min, // CRITICAL: prevent infinite height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated label/icon swap
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _StatusChip(
                key: ValueKey(k), 
                status: s,
              ),
            ),
            const SizedBox(height: 8),
            PipelineProgress(current: mapStatusToStep(s.name)),
            const SizedBox(height: 8),
            // Smooth progress bar
            if (show)
              TweenAnimationBuilder<double>(
                key: ValueKey('progress_$k'),
                tween: Tween<double>(begin: 0, end: p),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (_, value, __) => LinearProgressIndicator(value: value),
              ),
          ],
        );
      } catch (e) {
        // PipelineRx not found - return empty
        return const SizedBox.shrink();
      }
    });
  }
}

/// Internal status chip for the banner
class _StatusChip extends StatelessWidget {
  final RecordingStatus status;
  
  const _StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = StatusTheme.forStatus(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.getChipColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.getChipBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              theme.icon,
              key: ValueKey(theme.icon),
              size: 16,
              color: theme.getChipTextColor(context),
            ),
          ),
          const SizedBox(width: 8),
          
          // Label
          Text(
            theme.label,
            style: TextStyle(
              color: theme.getChipTextColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
