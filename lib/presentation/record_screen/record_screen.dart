import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/controllers/record_controller.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import '../../ui/app_spacing.dart';
import '../../utils/nav_utils.dart';
import '../../ui/widgets/record_button_lottie.dart';
import 'package:lashae_s_application/services/authoritative_upload_service.dart';
import 'package:lashae_s_application/services/file_upload_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import '../../ui/widgets/svn_scaffold_body.dart';
import '../../domain/summaries/summary_style.dart';
import '../../models/summary_style_option.dart';
import '../settings_screen/controller/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/widgets/pressable_scale.dart';
import '../../utils/haptics.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/record_waveform.dart';

class RecordScreen extends GetView<RecordController> {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[RECORD_WHO] RecordScreen.build using controller=${Get.find<RecordController>().runtimeType} hash=${Get.find<RecordController>().hashCode}');
    final uploadService = AuthoritativeUploadService();
    final tracker = PipelineTracker.I;
    final basePadding = AppSpacing.base(context);
    final screenPadding = AppSpacing.screenPadding(context);
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    // Reset per-recording style on first visit to this screen (per session)
    controller.resetStyleFromDefaultIfNeeded();

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Record'),
        automaticallyImplyLeading: false, // Root tab: no back/home chevron
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
              child: SVNScaffoldBody(
                padding: screenPadding.copyWith(
                  bottom: screenPadding.bottom + viewInsetsBottom + basePadding * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // small gap from app bar
                    AppSpacing.v(context, 1.0),
                    // 1) Upload section (tile width, centered)
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.9, // match Library tile width
                        child: _UploadSection(
                          uploadService: uploadService,
                          controller: controller,
                        ),
                      ),
                    ),

                    // 2) Spacing then Summary style selector (ALWAYS visible)
                    AppSpacing.v(context, 0.75),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.9,
                        child: Container(
                          padding: AppSpacing.sectionPadding(context),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.8)),
                          ),
                          child: Obx(() {
                            final currentStyle = controller.selectedSummaryStyle.value;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Summary style', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentStyle.label,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Change style',
                                  icon: const Icon(Icons.tune, color: Colors.white),
                                  onPressed: () async {
                                    final currentKey = currentStyle.key;

                                    final chosen = await showModalBottomSheet<SummaryStyleOption>(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (_) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final option in SummaryStyles.all)
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(minHeight: 44),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                                  visualDensity: const VisualDensity(vertical: -2),
                                                  title: Builder(
                                                    builder: (context) => Text(option.label, style: AppTextStyles.summaryOption(context)),
                                                  ),
                                                  trailing: currentKey == option.key
                                                      ? const Icon(Icons.check)
                                                      : const SizedBox.shrink(),
                                                  onTap: () => Navigator.pop(_, option),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );

                                    if (chosen != null) {
                                      // Update per-recording style using the new method
                                      controller.onSummaryStyleSelected(chosen);

                                      // Keep global default in sync with Settings so both screens share the same source of truth
                                      if (Get.isRegistered<SettingsController>()) {
                                        // Fire-and-forget; persistence handled by SettingsController
                                        Get.find<SettingsController>().setSummarizeStyle(chosen.key);
                                      }
                                    }
                                  },
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),

                    // 3) Divider + spacing
                    AppSpacing.v(context, 0.75),
                    const Divider(height: 1, thickness: 0.5),
                    AppSpacing.v(context, 1.0),

                      // 4) Recording section
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: _RecordingSection(controller: controller),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  final AuthoritativeUploadService uploadService;
  final RecordController controller;
  
  const _UploadSection({required this.uploadService, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.sectionPadding(context).copyWith(
        top: AppSpacing.base(context) * 0.75,
        bottom: AppSpacing.base(context) * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16), // match other large cards
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.base(context) * 0.35),
                Text(
                  'Upload .m4a, .mp3, .wav, .mp4, or .aac files',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Upload status and CTA
                Obx(() {
                  final uploadStatus = controller.uploadStatus.value;
                  final stage = controller.pipelineStage.value;
                  
                  // Idle state - no content
                  if (uploadStatus == UploadStatus.idle) {
                    return const SizedBox.shrink();
                  }
                  
                  // In progress state - show status text
                  if (uploadStatus == UploadStatus.inProgress) {
                    final tracker = PipelineTracker.I;
                    final activeId = tracker.recordingId.value;
                    // Only show if this is an upload (not live recording)
                    if (activeId == null || activeId == controller.currentRecordingId) {
                      return const SizedBox.shrink();
                    }
                    
                    final label = controller.pipelineStatusLabel(stage, isUpload: true);
                    if (label.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: stage == PipeStage.error
                              ? Colors.red.shade300
                              : Colors.white.withOpacity(0.85),
                        ),
                      ),
                    );
                  }
                  
                  // Completed state (success or error) - show message and CTA button
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          uploadStatus == UploadStatus.success
                              ? 'Summary ready.'
                              : 'Something went wrong.',
                          style: TextStyle(
                            fontSize: 12,
                            color: uploadStatus == UploadStatus.success
                                ? Colors.white.withOpacity(0.85)
                                : Colors.red.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => controller.onUploadTileCtaPressed(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: uploadStatus == UploadStatus.success
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.red.shade300.withOpacity(0.5),
                            ),
                            foregroundColor: uploadStatus == UploadStatus.success
                                ? Colors.white
                                : Colors.red.shade300,
                          ),
                          child: Text(
                            uploadStatus == UploadStatus.success
                                ? 'View in Library'
                                : 'View details',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            ...[
              SizedBox(height: AppSpacing.base(context) * 0.75),
              Obx(() {
                final uploadStatus = controller.uploadStatus.value;
                final isUploading = uploadStatus == UploadStatus.inProgress;
                
                return ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: Text(isUploading ? 'Uploading...' : 'Choose Audio File'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: isUploading ? null : () async {
                  debugPrint('[UPLOAD][RecordScreen] Choose Audio File tapped (ElevatedButton)');
                  // Immediately show activity in Upload tile
                  controller.onFilePicked();
                  
                  try {
                    final result = await FileUploadService.instance.pickAndUploadAudioFile(
                      summaryStyleOverride: Get.find<RecordController>().summaryStyleForThisRecording,
                    );
                    debugPrint('[UPLOAD][RecordScreen] result = $result');
                    final success = result['success'] == true;
                    final message = result['message'] ?? result['error'] ?? 'File uploaded';
                    
                    // Note: recording ID will be stored when pipeline completes in _listenToPipelineStage
                    // This ensures we have the correct ID even if the upload result format varies
                    
                    // Update upload status based on result
                    if (!success) {
                      controller.uploadStatus.value = UploadStatus.error;
                    }
                    // Success status is set in _listenToPipelineStage when pipeline completes
                    
                    // Only show snackbar on error (success is handled by CTA button)
                    if (!success) {
                      Get.snackbar(
                        'Upload Failed',
                        message,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  } catch (e, st) {
                    debugPrint('[UPLOAD][RecordScreen] exception: $e\n$st');
                    controller.uploadStatus.value = UploadStatus.error;
                    Get.snackbar(
                      'Upload Error',
                      'Failed to upload file: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                  },
                );
              }),
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
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Obx(() {
          final state = controller.recordState.value;
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tile-like card to match top tiles
              Container(
                padding: AppSpacing.sectionPadding(context),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Live',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.v(context, 0.5),
                    // Status text - state-driven
                    Obx(() {
                      final currentState = controller.recordState.value;
                      final label = switch (currentState) {
                        RecordState.recording => 'Recording',
                        RecordState.paused => 'Paused',
                        RecordState.processing => 'Processing…',
                        RecordState.error => 'Error',
                        _ => 'Tap record to start a live note',
                      };
                      return Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: currentState == RecordState.error
                              ? Colors.red.shade300
                              : Colors.white.withValues(alpha: currentState == RecordState.processing ? 0.9 : 0.75),
                        ),
                      );
                    }),
                    // Dynamic waveform region with AnimatedSize
                    Obx(() {
                      final isRecording = controller.isRecording;
                      final amp = (controller.amplitude.value).clamp(0.0, 1.0);
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: isRecording
                            ? Column(
                                children: [
                                  const SizedBox(height: 12),
                                  RecordWaveform(amplitude: amp),
                                  const SizedBox(height: 12),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    }),
                    // Controls row (start + stop)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Primary: Start/Pause/Resume button - state-driven
                        Obx(() {
                          final currentState = controller.recordState.value;
                          IconData icon;
                          Color buttonColor;
                          VoidCallback? onPressed;

                          switch (currentState) {
                            case RecordState.idle:
                            case RecordState.error:
                              icon = Icons.mic;
                              buttonColor = const Color(0xFF25D366); // green
                              onPressed = () => controller.startRecording();
                              break;
                            case RecordState.recording:
                              icon = Icons.pause_rounded;
                              buttonColor = Colors.grey.shade400;
                              onPressed = () => controller.pauseRecording();
                              break;
                            case RecordState.paused:
                              icon = Icons.play_arrow_rounded;
                              buttonColor = const Color(0xFF25D366); // green
                              onPressed = () => controller.resumeRecording();
                              break;
                            case RecordState.processing:
                              icon = Icons.mic;
                              buttonColor = Colors.grey.shade600;
                              onPressed = null; // Disabled while processing
                              break;
                          }

                          return PressableScale(
                            onTap: onPressed,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: buttonColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 20),
                        // Secondary Stop button - state-driven
                        Obx(() {
                          final currentState = controller.recordState.value;
                          final isActive = currentState == RecordState.recording || currentState == RecordState.paused;

                          return PressableScale(
                            onTap: isActive
                                ? () async {
                                    debugPrint('[RECORD_UI] STOP button tapped, state=$currentState');
                                    await controller.stopRecording();
                                  }
                                : null,
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.4,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stop, color: Colors.black87, size: 24),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              // Error message if any
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                final errorTheme = Theme.of(context);
                return Column(
                  children: [
                    AppSpacing.v(context, 0.75),
                    Container(
                      padding: AppSpacing.sectionPadding(context),
                      decoration: BoxDecoration(
                        color: errorTheme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        style: errorTheme.textTheme.bodySmall?.copyWith(
                          color: errorTheme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        }),
      ),
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