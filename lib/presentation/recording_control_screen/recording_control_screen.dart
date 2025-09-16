import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/web_audio_recorder.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_control_controller.dart';

// Add this import for Uint8List

class RecordingControlScreen extends StatefulWidget {
  RecordingControlScreen({Key? key}) : super(key: key);

  @override
  _RecordingControlScreenState createState() => _RecordingControlScreenState();
}

class _RecordingControlScreenState extends State<RecordingControlScreen> {
  // Timer and recording state
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _isRecording = false;
  bool _hasBlob = false;
  Uint8List? _audioFile;

  // Recording service
  final WebAudioRecorder _audioRecorder = WebAudioRecorder.instance;

  // Error handling
  bool _showErrorBanner = false;
  String _errorMessage = '';

  // Get controller
  RecordingControlController get controller =>
      Get.find<RecordingControlController>();

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    // Check if we have review data from arguments (from Stop navigation)
    final arguments = Get.arguments as Map<String, dynamic>?;
    final reviewFile = arguments?['file'] as Uint8List?;
    final reviewDurationMs = arguments?['durationMs'] as int? ?? 0;

    if (reviewFile != null && reviewDurationMs > 0) {
      // Initialize review state
      setState(() {
        _audioFile = reviewFile;
        _hasBlob = true;
        _elapsed = Duration(milliseconds: reviewDurationMs);
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  /// Format duration to MM:SS
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Start timer
  void _startTimer() {
    _ticker?.cancel();
    setState(() {
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  /// Stop timer
  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Request microphone permission (placeholder implementation)
  Future<bool> requestMicrophonePermission() async {
    try {
      // The WebAudioRecorder.startRecording() already handles permission request
      // This is just a placeholder for explicit permission checking if needed
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Record button action - start recorder and navigate to ActiveRecording
  Future<void> _onRecord() async {
    try {
      final ok = await requestMicrophonePermission();
      if (!ok) {
        _showError('Microphone permission denied');
        return;
      }

      // Start recording service
      await _audioRecorder.startRecording();

      // Navigate to active recording screen with startedAt timestamp
      Get.toNamed(
        AppRoutes.activeRecordingScreen,
        arguments: {'startedAt': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  /// Redo action - reset state to idle
  Future<void> _onRedo() async {
    // Delete temp file if created (best effort)
    _audioFile = null;

    _stopTimer();
    setState(() {
      _elapsed = Duration.zero;
      _isRecording = false;
      _hasBlob = false;
      _audioFile = null;
    });
    _clearError();

    // Navigate back to recording control in idle state
    Get.offNamed(AppRoutes.recordingControlScreen);
  }

  /// Save action with gating
  Future<void> _onSave() async {
    // Guard: if file null or duration 0 → error banner, return
    if (_audioFile == null || (_elapsed.inMilliseconds == 0)) {
      _showError('No recording data. Please record first.');
      return;
    }

    // Call the controller's save method with our recording data
    try {
      controller.setRecordingData(_audioFile!, _elapsed.inMilliseconds);
      await controller.onSavePressed();
    } catch (e) {
      _showError('Failed to save recording: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _showErrorBanner = true;
    });
  }

  /// Clear error message
  void _clearError() {
    setState(() {
      _showErrorBanner = false;
      _errorMessage = '';
    });
  }

  /// Dismiss error banner
  void _dismissError() {
    setState(() {
      _showErrorBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in review mode from route arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    final isReviewMode = arguments?.containsKey('file') == true;

    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        width: double.infinity,
        height: 852.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content section
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 102.h),
                padding: EdgeInsets.only(left: 50.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 2.h),
                      child: Text(
                        _isRecording
                            ? 'Recording in progress...'
                            : 'Recording stopped',
                        style: TextStyleHelper.instance.title16RegularOpenSans
                            .copyWith(height: 1.38),
                      ),
                    ),
                    SizedBox(height: 256.h),
                  ],
                ),
              ),
            ),

            // Overlay content with header and bottom sheet
            Opacity(
              opacity: 0.8,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: appTheme.white_A700,
                child: Column(
                  children: [
                    // Custom header section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: appTheme.white_A700,
                        border: Border(
                          bottom: BorderSide(
                            color: appTheme.color7FDEE1,
                            width: 1.h,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Status bar section with icons
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.h,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4.h, left: 10.h),
                                  child: CustomImageView(
                                    imagePath: ImageConstant.imgGroup,
                                    height: 10.h,
                                    width: 26.h,
                                  ),
                                ),
                                CustomImageView(
                                  imagePath: ImageConstant.imgGroupGray900,
                                  height: 10.h,
                                  width: 64.h,
                                ),
                              ],
                            ),
                          ),

                          // Header with title, bell icon, and profile
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.fromLTRB(16.h, 0, 16.h, 10.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Spacer(),
                                Container(
                                  margin: EdgeInsets.only(bottom: 4.h),
                                  child: Text(
                                    'Recorder',
                                    style: TextStyleHelper
                                        .instance.title18BoldQuattrocento
                                        .copyWith(height: 1.11),
                                  ),
                                ),
                                Spacer(),
                                CustomImageView(
                                  imagePath: ImageConstant.imgIconBell,
                                  height: 22.h,
                                  width: 22.h,
                                ),
                                Container(
                                  height: 36.h,
                                  width: 36.h,
                                  margin: EdgeInsets.only(left: 16.h),
                                  decoration: BoxDecoration(
                                    color: appTheme.deep_purple_50,
                                    borderRadius: BorderRadius.circular(18.h),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomImageView(
                                        imagePath: ImageConstant.imgRectangle1,
                                        height: 36.h,
                                        width: 36.h,
                                        fit: BoxFit.cover,
                                        radius: BorderRadius.circular(18.h),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    // Error banner (conditionally shown)
                    _showErrorBanner
                        ? Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(horizontal: 16.h),
                            padding: EdgeInsets.all(12.h),
                            decoration: BoxDecoration(
                              color: appTheme.red_400.withAlpha(26),
                              borderRadius: BorderRadius.circular(8.h),
                              border: Border.all(
                                  color: appTheme.red_400, width: 1.h),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error,
                                    color: appTheme.red_400, size: 20.h),
                                SizedBox(width: 8.h),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyleHelper
                                        .instance.body12RegularOpenSans
                                        .copyWith(color: appTheme.red_400),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _dismissError,
                                  child: Icon(Icons.close,
                                      color: appTheme.red_400, size: 20.h),
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),

                    SizedBox(height: 8.h),

                    // Bottom sheet section with review section logic
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: appTheme.white_A700,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.h),
                          topRight: Radius.circular(16.h),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appTheme.color1F0C17,
                            blurRadius: 1,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24.h),
                      child: (_hasBlob || isReviewMode)
                          ? _buildReviewSection()
                          : _buildIdleSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 0,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
    // Disable navigation during processing or recording
    if (controller.isUploading.value ||
        controller.isProcessing.value ||
        _isRecording) {
      return;
    }

    switch (index) {
      case 0:
        Get.toNamed(AppRoutes.homeScreen);
        break;
      case 1:
        Get.toNamed(AppRoutes.recordingLibraryScreen);
        break;
      case 2:
        Get.toNamed(AppRoutes.settingsScreen);
        break;
    }
  }

  /// Build idle section - "Ready to Record" state
  Widget _buildIdleSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle indicator
        CustomImageView(
          imagePath: ImageConstant.imgLine,
          height: 4.h,
          width: 48.h,
        ),

        SizedBox(height: 18.h),

        // Title
        Text(
          'Ready to Record',
          style: TextStyleHelper.instance.title20BoldQuattrocento
              .copyWith(height: 1.15),
        ),

        SizedBox(height: 4.h),

        // Subtitle
        Text(
          'Tap Record to start recording audio.',
          style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
            color: appTheme.gray_700,
            height: 1.43,
          ),
        ),

        SizedBox(height: 18.h),

        // Elapsed time (shows 00:00 in idle state)
        Text(
          _fmt(_elapsed),
          style: TextStyleHelper.instance.title20RegularRoboto
              .copyWith(height: 1.15),
        ),

        SizedBox(height: 22.h),

        // Record button
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.blue_200_01,
              padding: EdgeInsets.symmetric(
                horizontal: 30.h,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.h),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgMic,
                  height: 20.h,
                  width: 20.h,
                ),
                SizedBox(width: 8.h),
                Text(
                  'Record',
                  style:
                      TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                    color: appTheme.white_A700,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Cancel button
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            'Cancel',
            style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
              color: appTheme.gray_700,
              height: 1.43,
            ),
          ),
        ),
      ],
    );
  }

  /// Build review section - Save/Redo panel with ReviewSection widget
  Widget _buildReviewSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle indicator
        CustomImageView(
          imagePath: ImageConstant.imgLine,
          height: 4.h,
          width: 48.h,
        ),

        SizedBox(height: 18.h),

        // Title - matches user requirement "Stop recording?"
        Text(
          'Stop recording?',
          style: TextStyleHelper.instance.title20BoldQuattrocento
              .copyWith(height: 1.15),
        ),

        SizedBox(height: 4.h),

        // Subtitle
        Text(
          'Save to process or Redo to record again.',
          style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
            color: appTheme.gray_700,
            height: 1.43,
          ),
        ),

        SizedBox(height: 18.h),

        // Elapsed time (format mm:ss from durationMs)
        Text(
          _fmt(_elapsed),
          style: TextStyleHelper.instance.title20RegularRoboto
              .copyWith(height: 1.15),
        ),

        SizedBox(height: 22.h),

        // Save button - enabled only if file != null && durationMs > 0
        Obx(() => Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (controller.isUploading.value ||
                        controller.isProcessing.value ||
                        _audioFile == null ||
                        (_elapsed.inMilliseconds == 0))
                    ? null
                    : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (controller.isUploading.value ||
                          controller.isProcessing.value ||
                          _audioFile == null ||
                          (_elapsed.inMilliseconds == 0))
                      ? appTheme.gray_300
                      : appTheme.blue_200_01,
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.h,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controller.isUploading.value ||
                        controller.isProcessing.value)
                      SizedBox(
                        width: 20.h,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.h,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              appTheme.white_A700),
                        ),
                      )
                    else
                      CustomImageView(
                        imagePath: ImageConstant.imgSave,
                        height: 20.h,
                        width: 20.h,
                      ),
                    SizedBox(width: 8.h),
                    Text(
                      controller.isUploading.value
                          ? 'Uploading...'
                          : controller.isProcessing.value
                              ? 'Processing...'
                              : 'Save',
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(
                        color: appTheme.cyan_900,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            )),

        SizedBox(height: 12.h),

        // Redo button
        Obx(() => Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (controller.isUploading.value ||
                        controller.isProcessing.value)
                    ? null
                    : _onRedo,
                style: OutlinedButton.styleFrom(
                  backgroundColor: appTheme.white_A700,
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.h,
                    vertical: 12.h,
                  ),
                  side: BorderSide(
                    color: (controller.isUploading.value ||
                            controller.isProcessing.value)
                        ? appTheme.gray_300
                        : appTheme.red_400,
                    width: 1.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgRedo2,
                      height: 20.h,
                      width: 20.h,
                    ),
                    SizedBox(width: 8.h),
                    Text(
                      'Redo',
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(
                        color: (controller.isUploading.value ||
                                controller.isProcessing.value)
                            ? appTheme.gray_500
                            : appTheme.red_400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            )),

        SizedBox(height: 24.h),

        // Cancel button (disabled during processing)
        Obx(() => GestureDetector(
              onTap: (controller.isUploading.value ||
                      controller.isProcessing.value)
                  ? null
                  : () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                  color: (controller.isUploading.value ||
                          controller.isProcessing.value)
                      ? appTheme.gray_300
                      : appTheme.gray_700,
                  height: 1.43,
                ),
              ),
            )),
      ],
    );
  }
}
