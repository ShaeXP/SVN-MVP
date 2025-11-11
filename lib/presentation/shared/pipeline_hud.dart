import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/pipeline_tracker.dart';
import '../../ui/widgets/card_surface.dart';
import '../../app/navigation/bottom_nav_controller.dart';
import '../../app/routes/app_routes.dart';

class PipelineHUD extends StatefulWidget {
  const PipelineHUD({super.key, this.autonavigateWhenReady = true});
  final bool autonavigateWhenReady;

  @override
  State<PipelineHUD> createState() => _PipelineHUDState();
}

class _PipelineHUDState extends State<PipelineHUD> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final t = PipelineTracker.I;
    
    // Auto-jump when ready (once) - use separate Obx for this
    return Obx(() {
      final stage = t.status.value;
      
      if (widget.autonavigateWhenReady && stage == PipeStage.ready && t.recordingId.value != null && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Get.back(); // Close HUD
            BottomNavController.I.pushChildOf(
              tabIndex: 2,
              route: '/recording-summary',
              arguments: {'id': t.recordingId.value},
            );
          }
        });
      }
      
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CardSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Processing your note', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _ReactiveStepRow(label: 'Uploaded', stage: PipeStage.uploaded),
                _ReactiveStepRow(label: 'Transcribing', stage: PipeStage.transcribing),
                _ReactiveStepRow(label: 'Summarizing', stage: PipeStage.summarizing),
                _ReactiveStepRow(label: 'Ready', stage: PipeStage.ready),
                _ErrorDisplay(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back(); // Close HUD
                        // Navigate to Library with focus on current recording
                        BottomNavController.I.pushChildOf(
                          tabIndex: 2, // Library tab
                          route: Routes.recordingLibraryScreen,
                          arguments: {'focusId': t.recordingId.value},
                        );
                      },
                      child: const Text('View in Library'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Get.back(); // Close HUD
                        t.stop(); // Stop tracking
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _hasNavigated = false;
    super.dispose();
  }
}

class _ReactiveStepRow extends StatelessWidget {
  const _ReactiveStepRow({required this.label, required this.stage});
  final String label;
  final PipeStage stage;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = PipelineTracker.I;
      final currentStage = t.status.value;
      
      final isActive = currentStage == stage;
      final isDone = currentStage.index > stage.index || 
                    (stage == PipeStage.uploaded && currentStage.index >= PipeStage.uploaded.index);
      
      return _StepRow(
        label: label,
        active: isActive,
        done: isDone,
      );
    });
  }
}

class _ErrorDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = PipelineTracker.I;
      final stage = t.status.value;
      final msg = t.message.value;
      
      if (stage != PipeStage.error) return const SizedBox.shrink();
      
      return Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: $msg',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.active, required this.done});
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final color = done 
        ? colorScheme.primary 
        : (active ? colorScheme.secondary : colorScheme.onSurface.withValues(alpha: 0.4));
    
    final icon = done 
        ? Icons.check_circle 
        : (active ? Icons.timelapse : Icons.radio_button_unchecked);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: active || done ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (active && !done) 
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }
}

