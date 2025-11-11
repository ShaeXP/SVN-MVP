import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../feature_flags.dart';
import '../../controllers/progress_controller.dart';
import 'unified_status_chip.dart';

class PipelineProgressBanner extends StatelessWidget {
  const PipelineProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ProgressUI.enabled) return const SizedBox.shrink();
    
    // Use the new unified pipeline banner
    return const UnifiedPipelineBanner();
  }
}
