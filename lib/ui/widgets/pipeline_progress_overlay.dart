import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pipeline_progress_controller.dart';
import 'pipeline_ring_lottie.dart';

class PipelineProgressOverlay extends StatelessWidget {
  const PipelineProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<PipelineProgressController>();
      
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }

      return Stack(
        children: [
          // Semi-transparent backdrop
          Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
          
          // Centered card
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      "Processing your note…",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Animated progress ring
                    PipelineRingLottie(
                      progress: (controller.percent.value ?? 0.0) / 100.0,
                      stage: controller.stage.value.toLowerCase(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stage chips
                    _buildStageChips(context, controller),
                    
                    const SizedBox(height: 16),
                    
                    // Progress indicator
                    _buildProgressIndicator(context, controller),
                    
                    const SizedBox(height: 8),
                    
                    // Subtext
                    Text(
                      "You can keep browsing; we'll take you to the summary when it's ready.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStageChips(BuildContext context, PipelineProgressController controller) {
    final stages = ['Uploading', 'Transcribing', 'Summarizing', 'Finalizing'];
    final currentStage = controller.stage.value;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: stages.map((stage) {
        final isActive = stage == currentStage;
        final isCompleted = _isStageCompleted(stage, currentStage);
        
        // Get stage-specific colors
        Color getStageColor() {
          switch (stage) {
            case 'Uploading':
              return Colors.blue;
            case 'Transcribing':
              return Colors.orange;
            case 'Summarizing':
              return Colors.purple;
            case 'Finalizing':
              return Colors.green;
            default:
              return Theme.of(context).colorScheme.primary;
          }
        }
        
        return Chip(
          label: Text(
            stage,
            style: TextStyle(
              color: isActive || isCompleted 
                ? Colors.white 
                : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          backgroundColor: isActive 
            ? getStageColor()
            : isCompleted
              ? getStageColor().withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, PipelineProgressController controller) {
    final percent = controller.percent.value;
    
    if (percent != null) {
      // Show percentage with progress bar
      return Column(
        children: [
          Text(
            "${percent.toInt()}%",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent / 100.0,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else {
      // Show spinner
      return const CircularProgressIndicator();
    }
  }

  bool _isStageCompleted(String stage, String currentStage) {
    final stageOrder = ['Uploading', 'Transcribing', 'Summarizing', 'Finalizing'];
    final stageIndex = stageOrder.indexOf(stage);
    final currentIndex = stageOrder.indexOf(currentStage);
    
    // Handle "Processing" stage as a special case
    if (currentStage == 'Processing') {
      return false; // No stages are completed when in generic processing
    }
    
    return stageIndex < currentIndex;
  }
}
