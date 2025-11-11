import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/controllers/record_controller.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import '../../ui/app_spacing.dart';
import '../../utils/nav_utils.dart';
import '../../ui/widgets/record_button_lottie.dart';
import '../../ui/widgets/animated_pipeline_card.dart';
import '../../ui/util/pipeline_stage.dart';
import '../../widgets/pipeline_progress_cta.dart';
import 'package:lashae_s_application/services/authoritative_upload_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import '../../ui/widgets/unified_status_chip.dart';
import '../../ui/widgets/svn_scaffold_body.dart';

class RecordScreen extends GetView<RecordController> {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uploadService = AuthoritativeUploadService();
    final tracker = PipelineTracker.I;
    final basePadding = AppSpacing.base(context);
    final screenPadding = AppSpacing.screenPadding(context);
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Record'),
        leading: IconButton(
          key: const Key('nav_home_from_record'),
          tooltip: 'Home',
          icon: const Icon(Icons.home_outlined),
          onPressed: NavUtils.goHome,
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BrandGradientBackground()),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: Obx(() {
                final recordingId = tracker.recordingId.value;
                final stage = tracker.status.value;
                final isPipelineActive =
                    recordingId != null && stage != PipeStage.local;

                final padding = screenPadding.copyWith(
                  bottom: screenPadding.bottom + viewInsetsBottom + basePadding * 0.75,
                );

                Widget? banner;
                if (isPipelineActive && recordingId != null) {
                  banner = Padding(
                    padding: EdgeInsets.fromLTRB(basePadding, 0, basePadding, basePadding),
                    child: SizedBox(
                      height: 80,
                      child: UnifiedPipelineBanner(recordingId: recordingId),
                    ),
                  );
                }

                return SVNScaffoldBody(
                  banner: banner,
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: (MediaQuery.of(context).size.height * 0.35)
                            .clamp(220.0, 360.0),
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.78,
                            child: Obx(() {
                              final currentStage = tracker.status.value;
                              final activeId = tracker.recordingId.value;
                              final active =
                                  activeId != null && currentStage != PipeStage.local;
                              final uiStage =
                                  active ? mapStatusToPipeStage(currentStage.name) : null;
                              return _UploadSection(
                                uploadService: uploadService,
                                stage: uiStage,
                              );
                            }),
                          ),
                        ),
                      ),
                      AppSpacing.v(context, 1.5),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      AppSpacing.v(context, 1.5),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: _RecordingSection(controller: controller),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  final AuthoritativeUploadService uploadService;
  final PipeStage? stage;
  
  const _UploadSection({required this.uploadService, this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.sectionPadding(context),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: stage != null
                  ? AnimatedPipelineCard(stage: stage!, key: ValueKey(stage))
                  : Column(
                      key: const ValueKey('pipeline-idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                        AppSpacing.v(context, 0.75),
                        Text(
                          'Upload Audio File',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        AppSpacing.v(context, 0.4),
                        Text(
                          'Upload .m4a, .mp3, .wav, .mp4, or .aac files',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
            if (stage == null) ...[
              AppSpacing.v(context, 1.25),
              PipelineProgressCTA(
                idleLabel: 'Choose Audio File',
                idleIcon: Icons.upload_file,
                onStartAction: () async {
                  try {
                    final result = await uploadService.pickAndUploadAudioFile();
                    if (result['success']) {
                      // Tracking is already started by AuthoritativeUploadService.uploadWithAuthoritativeFlow()
                      // No need to start tracking again here
                      final recordingId = result['recording_id'] as String?;
                      if (recordingId == null) {
                        // Fallback toast if no recording_id
                        Get.snackbar(
                          'Upload Complete',
                          result['message'] ?? 'File uploaded successfully',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    } else {
                      // Error case - widget will show error state
                      final message = result['message'] ?? result['error'] ?? 'Upload failed';
                      Get.snackbar(
                        'Upload Failed',
                        message,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Upload Error',
                      'Failed to upload file: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordingSection extends StatelessWidget {
  final RecordController controller;
  
  const _RecordingSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Or Record Live',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.v(context, 1.25),
        Obx(() {
          final state = controller.recordState.value;

          return Column(
            children: [
              RecordButtonLottie(
                isRecording: state == RecordState.recording,
                onTap: controller.toggleRecording,
              ),
              AppSpacing.v(context, 0.75),
              Text(
                state == RecordState.idle
                    ? 'Tap to Record'
                    : state == RecordState.recording
                        ? 'Recording… Tap to Stop'
                        : 'Processing…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              // Error message if any
              if (controller.errorMessage.value.isNotEmpty) ...[
                AppSpacing.v(context, 0.5),
                Container(
                  padding: EdgeInsets.all(AppSpacing.base(context)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _MicButton({
    required this.isRecording,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isDisabled
            ? const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 48,
              ),
      ),
    );
  }
}