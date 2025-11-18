import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:lashae_s_application/services/authoritative_upload_service.dart';
import 'package:lashae_s_application/services/pipeline_tracker.dart';
import 'package:lashae_s_application/services/haptics_service.dart';
import 'package:lashae_s_application/ui/app_spacing.dart';
import 'package:lashae_s_application/ui/widgets/animated_pipeline_card.dart';
import 'package:lashae_s_application/ui/widgets/animated_waveform.dart';
import 'package:lashae_s_application/ui/visuals/brand_background.dart';
import 'package:lashae_s_application/services/logger.dart';
import 'package:lashae_s_application/widgets/pipeline_progress_cta.dart';
import 'package:lashae_s_application/utils/recording_permission_helper.dart';
import 'package:lashae_s_application/services/permission_service.dart';
import 'package:lashae_s_application/presentation/recording_screen/recording_screen_controller.dart';
import 'package:lashae_s_application/utils/summary_navigation.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final FlutterSoundRecorder _rec = FlutterSoundRecorder();
  final _amplitude = ValueNotifier<double>(0.0);
  StreamSubscription<RecordingDisposition>? _ampSub;
  Timer? _fallbackTimer;
  bool _sessionOpen = false;
  bool _testMode = false; // For testing widget rendering
  int _waveformKey = 0;
  String? recordedFilePath;
  bool _ready = false;
  bool _isRecording = false;
  bool _isPaused = false;
  
  late final RecordingScreenController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    if (!Get.isRegistered<RecordingScreenController>()) {
      Get.put(RecordingScreenController());
    }
    _controller = Get.find<RecordingScreenController>();
    _init();
  }

  Future<void> _init() async {
    final hasPermission = await Permission.microphone.status == PermissionStatus.granted;
    await _ensureSession();
    if (mounted) {
      setState(() => _ready = hasPermission);
    }
    
    // Test mode: simulate amplitude to verify widget rendering
    // Remove this after confirming widget works
    // _startTestMode();
  }
  
  void _startTestMode() {
    _testMode = true;
    debugPrint('[RecordingScreen] Starting test mode - simulating amplitude');
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_testMode) {
        timer.cancel();
        return;
      }
      final time = DateTime.now().millisecondsSinceEpoch;
      final testAmplitude = 0.3 + (math.sin(time / 200.0) * 0.4);
      _amplitude.value = testAmplitude.clamp(0.0, 1.0);
    });
  }
  
  void _stopTestMode() {
    _testMode = false;
  }

  Future<void> _ensureSession() async {
    if (_sessionOpen) return;
    try {
      await _rec.openRecorder();
      _sessionOpen = true;
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  Future<String> _makePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return "${dir.path}/svnote_$ts.m4a";
  }

  Future<void> _start() async {
    // Use permission helper for user-friendly permission flow
    await RecordingPermissionHelper.startRecordingWithPermissions(
      context: context,
      onPermissionGranted: () async {
        // Permission granted, proceed with recording
        await _startRecording();
      },
    );
  }

  Future<void> _startRecording() async {
    await HapticsService.mediumTap();
    
    final hasPermission = await Permission.microphone.status == PermissionStatus.granted;
    if (!hasPermission) return;
    
    final path = await _makePath();
    
    // Clear previous amplitude history
    _amplitude.value = 0.0;
    
    await _ensureSession();
    // Use 40ms for smoother updates (matches typical audio frame rate)
    await _rec.setSubscriptionDuration(const Duration(milliseconds: 40));
    await _rec.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );
    
    // Subscribe immediately after startRecorder (matching working pattern)
    _listenAmplitude();
    
    if (mounted) {
      setState(() {
        _isRecording = true;
        _isPaused = false;
      });
    }
  }
  
  void _listenAmplitude() {
    _ampSub?.cancel();
    
    try {
      // Use force unwrap like the working recording_controller.dart pattern
      final progressStream = _rec.onProgress;
      if (progressStream == null) {
        debugPrint('[RecordingScreen] onProgress stream is null - using fallback timer');
        _startFallbackAmplitudeTimer();
        return;
      }
      
      debugPrint('[RecordingScreen] Subscribing to amplitude stream');
      _ampSub = progressStream.listen(
        (disposition) {
          // Use the decibel value from RecordingDisposition
          final db = disposition.decibels;
          if (db != null) {
            // Normalize: handle both positive and negative dB values
            // Typical range: -60 (silence) to +40 (loud), map to 0.0-1.0
            // Use wider range to prevent all values hitting 1.0
            final norm = ((db + 60) / 100).clamp(0.0, 1.0);
            _amplitude.value = norm;
            // Only log occasionally to reduce performance impact
            // debugPrint('[RecordingScreen] Amplitude: db=$db, norm=$norm');
          } else {
            // If decibels is null, use a small default value to show activity
            _amplitude.value = 0.15;
          }
        },
        onError: (error) {
          debugPrint('[RecordingScreen] Amplitude stream error: $error - switching to fallback');
          _startFallbackAmplitudeTimer();
        },
        onDone: () {
          debugPrint('[RecordingScreen] Amplitude stream done');
        },
      );
    } catch (e) {
      debugPrint('[RecordingScreen] Error setting up amplitude stream: $e - using fallback');
      _startFallbackAmplitudeTimer();
    }
  }
  
  void _startFallbackAmplitudeTimer() {
    _fallbackTimer?.cancel();
    debugPrint('[RecordingScreen] Starting fallback amplitude timer');
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isRecording || _isPaused) {
        // When paused or not recording, gradually reduce amplitude
        if (_amplitude.value > 0.0) {
          _amplitude.value = (_amplitude.value * 0.9).clamp(0.0, 1.0);
        }
        return;
      }
      
      // Simulate amplitude variation for visualization
      final time = DateTime.now().millisecondsSinceEpoch;
      final baseAmplitude = 0.3 + (math.sin(time / 200.0) * 0.3);
      final variation = math.sin(time / 100.0) * 0.2;
      final simulatedAmplitude = (baseAmplitude + variation).clamp(0.0, 1.0);
      _amplitude.value = simulatedAmplitude;
    });
  }
  
  void _stopFallbackAmplitudeTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void _cancelAmplitude() {
    _ampSub?.cancel();
    _ampSub = null;
    _stopFallbackAmplitudeTimer();
  }

  Future<void> _pause() async {
    await _rec.pauseRecorder();
    // Amplitude stream continues but will naturally reduce when paused
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = true;
      });
    }
  }

  Future<void> _resume() async {
    await _rec.resumeRecorder();
    // Amplitude stream continues automatically
    if (mounted) {
      setState(() {
        _isRecording = true;
        _isPaused = false;
      });
    }
  }

  Future<void> _stop() async {
    if (_isRecording || _isPaused) {
      await HapticsService.mediumTap();
      
      recordedFilePath = await _rec.stopRecorder();
      
      // Cancel amplitude stream
      _cancelAmplitude();
      
      // Reset amplitude and waveform (by changing key to force widget recreation)
      _amplitude.value = 0.0;
      
      if (!mounted) return;
      
      setState(() {
        _isRecording = false;
        _isPaused = false;
        // Change key to reset waveform widget (clear history)
        _waveformKey = DateTime.now().millisecondsSinceEpoch;
      });

      if (recordedFilePath == null || recordedFilePath!.isEmpty) {
        logx('[PIPELINE] Recording stopped but no file path returned', tag: 'PIPE', error: 'NoFilePath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording stopped but file not found")),
        );
        return;
      }

      // Start pipeline with the recorded file
      logx('[PIPELINE] Starting pipeline for recorded file: $recordedFilePath', tag: 'PIPE');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Processing recording...")),
      );

      try {
        final uploadService = AuthoritativeUploadService();
        final result = await uploadService.startPipelineFromLocalFile(
          localFilePath: recordedFilePath!,
          sourceType: 'record',
        );

        if (!mounted) return;

        if (result['success'] == true) {
          // Store upload info for potential retry
          final recordingId = result['recording_id'] as String?;
          _controller.storeUploadInfo(
            recordingId: recordingId,
            localFilePath: recordedFilePath,
            storagePath: result['storage_path'] as String?,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Recording queued for processing'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          logx('[PIPELINE] Pipeline start failed: ${result['error']}', tag: 'PIPE', error: result['error']);
          // Store upload info even on failure for retry
          _controller.storeUploadInfo(
            localFilePath: recordedFilePath,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to process recording'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e, stackTrace) {
        logx('[PIPELINE] Exception starting pipeline: $e', tag: 'PIPE', error: e, stack: stackTrace);
        // Store upload info even on exception for retry
        _controller.storeUploadInfo(
          localFilePath: recordedFilePath,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing recording: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopTestMode();
    _cancelAmplitude();
    _stopFallbackAmplitudeTimer();
    _amplitude.dispose();
    _rec.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadService = AuthoritativeUploadService();
    final tracker = PipelineTracker.I;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1) Upload UI at top
                        _UploadSection(
                          uploadService: uploadService,
                          controller: _controller,
                          tracker: tracker,
                        ),

                        const SizedBox(height: 24),

                        // 2) Recording card in the middle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          height: 140,
                          child: Stack(
                            children: [
                              // Waveform fills most of the card
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: _amplitude,
                                    builder: (context, level, _) {
                                      return AnimatedWaveform(
                                        isActive: _isRecording,
                                        level: _isRecording ? level : null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Title overlay
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Record Live',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 3) Recording label + buttons at bottom (fixed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRecording)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Recording",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_ready) ...[
                            Builder(
                              builder: (context) {
                                Color primaryColor;
                                IconData primaryIcon;
                                VoidCallback primaryOnTap;

                                if (_isRecording) {
                                  // RECORDING: grey pause
                                  primaryColor = const Color(0xFFB0B4C2);
                                  primaryIcon = Icons.pause;
                                  primaryOnTap = _pause;
                                } else if (_isPaused) {
                                  // PAUSED: green play (resume)
                                  primaryColor = const Color(0xFF25D366);
                                  primaryIcon = Icons.play_arrow;
                                  primaryOnTap = _resume;
                                } else {
                                  // IDLE: green play (start)
                                  primaryColor = const Color(0xFF25D366);
                                  primaryIcon = Icons.play_arrow;
                                  primaryOnTap = _start;
                                }

                                return _CircleButton(
                                  color: primaryColor,
                                  onTap: primaryOnTap,
                                  icon: primaryIcon,
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                          ],
                          _CircleButton(
                            color: Colors.white,
                            onTap: _stop,
                            icon: Icons.stop,
                            iconColor: Colors.black87,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  final AuthoritativeUploadService uploadService;
  final RecordingScreenController controller;
  final PipelineTracker tracker;

  const _UploadSection({
    required this.uploadService,
    required this.controller,
    required this.tracker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.sectionPadding(context),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single Obx that directly reads uploadPanelState and tracker status
          Obx(() {
            final panelState = controller.uploadPanelState.value;
            final currentStage = tracker.status.value;
            final activeId = tracker.recordingId.value;
            
            switch (panelState) {
              case UploadPanelState.idle:
                return _buildIdleUploadCard(context);
              case UploadPanelState.uploading:
              case UploadPanelState.processing:
                // Read tracker status here to avoid nested Obx
                final active = activeId != null && currentStage != PipeStage.local;
                final uiStage = active ? currentStage : null;
                // When ready and we have an id, show the dedicated tappable CTA
                if (uiStage == PipeStage.ready && activeId != null && activeId.isNotEmpty) {
                  debugPrint('[RecordScreen] showing SummaryReadyCTA, stage=$currentStage, id=$activeId');
                  return SummaryReadyCTA(
                    recordingId: activeId,
                    onOpenSummary: (id) {
                      debugPrint('[RecordScreen] onOpenSummary id=$id');
                      // Reset pipeline state so the Record tab returns to idle UI on back
                      tracker.clearReadyState();
                      openRecordingSummary(recordingId: id);
                    },
                  );
                }
                // Otherwise show animated pipeline card
                return AnimatedPipelineCard(
                  stage: uiStage ?? PipeStage.uploading,
                  key: ValueKey('processing-${currentStage}'),
                );
              case UploadPanelState.error:
                return _buildErrorCard(context);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildIdleUploadCard(BuildContext context) {
    return Column(
      key: const ValueKey('upload-idle'),
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
        AppSpacing.v(context, 1.25),
        PipelineProgressCTA(
          idleLabel: 'Choose Audio File',
          idleIcon: Icons.upload_file,
          autoNavigate: false,
          onStartAction: () async {
            try {
              // Check file access permission before picking
              final permissionService = PermissionService.instance;
              final hasFilePermission = await permissionService.ensureFileAccessPermission();
              if (!hasFilePermission) {
                Get.snackbar(
                  'Permission Required',
                  'We need access to your files to upload a recording.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
                return;
              }

              final result = await uploadService.pickAndUploadAudioFile();
              if (result['success']) {
                final recordingId = result['recording_id'] as String?;
                // Store upload info for potential retry
                controller.storeUploadInfo(
                  recordingId: recordingId,
                  storagePath: result['storage_path'] as String?,
                );
                if (recordingId == null) {
                  Get.snackbar(
                    'Upload Complete',
                    result['message'] ?? 'File uploaded successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              } else {
                // Store upload info even on failure for retry
                final recordingId = result['recording_id'] as String?;
                controller.storeUploadInfo(
                  recordingId: recordingId,
                  storagePath: result['storage_path'] as String?,
                );
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
                'That file couldn\'t be opened. Try a different one or check your connection.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            }
          },
        ),
      ],
    );
  }


  Widget _buildErrorCard(BuildContext context) {
    // Show error card with retry/reset buttons
    return AnimatedPipelineCard(
      stage: PipeStage.error,
      key: const ValueKey('error'),
    );
  }
}

class _CircleButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  const _CircleButton({
    required this.color,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  double _scale = 1.0;

  void _animateTap() {
    setState(() => _scale = 0.95);
    widget.onTap();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: _animateTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: widget.icon == null
              ? null
              : Icon(widget.icon, color: widget.iconColor ?? Colors.white, size: 32),
        ),
      ),
    );
  }
}

