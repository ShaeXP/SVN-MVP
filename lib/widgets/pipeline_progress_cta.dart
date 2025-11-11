import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/pipeline_tracker.dart';
import '../utils/summary_navigation.dart';
import '../app/navigation/bottom_nav_controller.dart';
import '../app/routes/app_routes.dart';

/// Lightweight, non-blocking progress indicator for pipeline stages
/// Replaces CTA buttons during upload/processing with smooth transitions
class PipelineProgressCTA extends StatefulWidget {
  /// Callback when user wants to start upload/record
  final VoidCallback? onStartAction;
  
  /// Optional custom label for the idle state button
  final String? idleLabel;
  
  /// Optional custom icon for the idle state button
  final IconData? idleIcon;
  
  /// Whether to auto-navigate to summary when ready
  final bool autoNavigate;

  const PipelineProgressCTA({
    super.key,
    this.onStartAction,
    this.idleLabel,
    this.idleIcon,
    this.autoNavigate = true,
  });

  @override
  State<PipelineProgressCTA> createState() => _PipelineProgressCTAState();
}

class _PipelineProgressCTAState extends State<PipelineProgressCTA>
    with SingleTickerProviderStateMixin {
  late final PipelineTracker _tracker;
  Timer? _debounceTimer;
  DateTime? _activeStartTime;
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    // Get tracker instance once in initState
    _tracker = PipelineTracker.I;
    debugPrint('[PipelineProgressCTA] initState: tracker instance acquired');
    
    // Listen for stage changes to handle navigation
    if (widget.autoNavigate) {
      ever(_tracker.status, _onStageChanged);
    }
    // Listen for new recording IDs to reset navigation flag
    ever(_tracker.recordingId, (String? id) {
      if (id == null) {
        _hasNavigated = false;
      }
    });
  }

  void _onStageChanged(PipeStage stage) {
    if (!mounted) return;
    
    // Auto-navigate on ready (once)
    if (stage == PipeStage.ready && !_hasNavigated) {
      final recId = _tracker.recordingId.value;
      if (recId != null) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Use BottomNavController to properly navigate to Library tab
            // then push summary screen, avoiding nested home screens
            BottomNavController.I.pushChildOf(
              tabIndex: 2, // Library tab
              route: Routes.recordingSummaryScreen,
              arguments: {'recordingId': recId},
            );
          }
        });
      }
    }
  }

  /// Get user-friendly subtext for each stage
  String _getStageSubtext(PipeStage stage) {
    switch (stage) {
      case PipeStage.local:
      case PipeStage.uploading:
        return 'Uploading your recording';
      case PipeStage.uploaded:
        return 'Preparing for transcription';
      case PipeStage.transcribing:
        return 'Turning speech into text';
      case PipeStage.summarizing:
        return 'Creating summary';
      case PipeStage.ready:
        return 'Complete!';
      case PipeStage.error:
        return _tracker.message.value.isNotEmpty
            ? _tracker.message.value
            : 'Something went wrong';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stage = _tracker.status.value;
      final recId = _tracker.recordingId.value;
      // Debug logging
      debugPrint('[PipelineProgressCTA] stage=$stage, recId=$recId');
      
      // Consider active if tracking a recording and not in idle/ready/error final states
      // local stage can be active if we're just starting
      final isActive = recId != null && 
          stage != PipeStage.ready && 
          stage != PipeStage.error;

      // Track when active state starts for debounce
      if (isActive && _activeStartTime == null) {
        _activeStartTime = DateTime.now();
        // Start debounce timer - only show if >250ms
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) setState(() {});
        });
      } else if (!isActive) {
        _activeStartTime = null;
        _debounceTimer?.cancel();
      }

      // Check if we should show progress (active + past debounce)
      final shouldShowProgress = isActive && 
          (_activeStartTime == null || 
           DateTime.now().difference(_activeStartTime!).inMilliseconds >= 250);

      // Build appropriate state widget
      if (shouldShowProgress && stage == PipeStage.error) {
        return _buildErrorState(context);
      } else if (shouldShowProgress) {
        return _buildProgressState(context, stage);
      } else {
        return _buildIdleState(context);
      }
    });
  }

  Widget _buildIdleState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onStartAction,
        icon: Icon(widget.idleIcon ?? Icons.upload_file),
        label: Text(widget.idleLabel ?? 'Choose Audio File'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E88E5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressState(BuildContext context, PipeStage stage) {
    final progress = _tracker.progressPercentage;
    final label = _tracker.stageLabel;
    final subtext = _getStageSubtext(stage);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('progress-$stage'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stage label
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              semanticsLabel: 'Processing stage: $label',
            ),
            const SizedBox(height: 12),
            // Progress indicator
            SizedBox(
              height: 48,
              child: progress == 0.0 || progress == 1.0
                  ? const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  : CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      semanticsLabel: 'Progress: ${(progress * 100).toInt()}%',
                    ),
            ),
            const SizedBox(height: 12),
            // Subtext
            Text(
              subtext,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: const ValueKey('error'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload failed',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (_tracker.message.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _tracker.message.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // Reset tracking state and navigation flag
                _tracker.stop();
                _hasNavigated = false;
                _activeStartTime = null;
                _debounceTimer?.cancel();
                // Trigger retry action
                widget.onStartAction?.call();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

