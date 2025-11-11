import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';

import 'recording_controller.dart';
import 'recording_state.dart';
import '../../app/routes/app_routes.dart';
import '../../app/navigation/bottom_nav_controller.dart';
import '../../widgets/pipeline_progress_cta.dart';

class ActiveRecordingScreen extends StatefulWidget {
  const ActiveRecordingScreen({super.key});

  @override
  State<ActiveRecordingScreen> createState() => _ActiveRecordingScreenState();
}

class _ActiveRecordingScreenState extends State<ActiveRecordingScreen> {
  bool _didAutoUpload = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[NAV] → ActiveRecordingScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      final auto = (args is Map && args['autoUpload'] == true);
      if (auto && !_didAutoUpload) {
        _didAutoUpload = true;
        // Trigger upload file picker directly
        final c = Get.find<RecordingController>();
        c.onUploadFilePressed(context);
      }
    });
  }

  @override
  void dispose() {
    debugPrint('[NAV] back from ActiveRecordingScreen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RecordingController>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // If actively recording, show discard confirmation
        if (c.state.value == RecState.recording) {
          final shouldDiscard = await _showDiscardDialog(context);
          if (shouldDiscard == true) {
            await c.stop();
            await c.redo(); // Reset to idle state
            // Switch to home tab and reset navigation stack
            BottomNavController.I.goTab(0);
            final navState = Get.nestedKey(0)?.currentState;
            if (navState != null) {
              navState.popUntil((route) => route.isFirst);
            }
          }
        } else {
          // Switch to home tab and reset navigation stack
          BottomNavController.I.goTab(0);
          final navState = Get.nestedKey(0)?.currentState;
          if (navState != null) {
            navState.popUntil((route) => route.isFirst);
          }
        }
      },
      child: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                AppBar(
          title: const Text('Recording'),
          automaticallyImplyLeading: true,
          leading: BackButton(
            onPressed: () {
              if (c.state.value == RecState.recording) {
                // Show discard dialog for active recording
                _showDiscardDialog(context).then((shouldDiscard) {
                  if (shouldDiscard == true) {
                    c.stop().then((_) => c.redo());
                    // Switch to home tab and reset navigation stack
                    BottomNavController.I.goTab(0);
                    final navState = Get.nestedKey(0)?.currentState;
                    if (navState != null) {
                      navState.popUntil((route) => route.isFirst);
                    }
                  }
                });
              } else {
                // Switch to home tab and reset navigation stack
                BottomNavController.I.goTab(0);
                final navState = Get.nestedKey(0)?.currentState;
                if (navState != null) {
                  navState.popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        actions: [
          Obx(() => IconButton(
            tooltip: 'Upload file',
            icon: const Icon(Icons.upload_file),
            onPressed: c.isUploading.value ? null : () => c.onUploadFilePressed(context),
          )),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: kElevationToShadow[2],
            ),
            child: Column(
              children: [
                Obx(() => Text(c.clock, style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(height: 12),

                // Simple live waveform bar driven by amplitude
                Obx(() {
                  final h = 12 + (c.amplitude.value * 48); // 12..60
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Controls per FSM
                Obx(() {
                  switch (c.state.value) {
                    case RecState.idle:
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(onPressed: c.start, child: const Text('Record')),
                        ],
                      );
                    case RecState.recording:
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(onPressed: c.pause, child: const Text('Pause')),
                          const SizedBox(width: 12),
                          FilledButton(onPressed: c.stop, child: const Text('Stop')),
                        ],
                      );
                    case RecState.paused:
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(onPressed: c.resume, child: const Text('Resume')),
                          const SizedBox(width: 12),
                          FilledButton(onPressed: c.stop, child: const Text('Stop')),
                        ],
                      );
                    case RecState.stopped:
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(onPressed: c.redo, child: const Text('Redo')),
                          const SizedBox(width: 12),
                          Obx(() => FilledButton(
                                onPressed: c.saving.value ? null : c.save,
                                child: Text(c.saving.value ? 'Saving…' : 'Save'),
                              )),
                        ],
                      );
                  }
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Progress-aware upload CTA
          PipelineProgressCTA(
            idleLabel: 'Upload file',
            idleIcon: Icons.upload_file,
            autoNavigate: true,
            onStartAction: () => c.onUploadFilePressed(context),
          ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text('You are currently recording. Are you sure you want to discard this recording and go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}