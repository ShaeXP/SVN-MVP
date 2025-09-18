import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lashae_s_application/widgets/session_debug_overlay.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_summary_controller.dart';

class RecordingSummaryScreen extends StatelessWidget {
  RecordingSummaryScreen({Key? key}) : super(key: key);

  final RecordingSummaryController controller =
      Get.put(RecordingSummaryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorder')),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: appTheme.color281E12,
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Obx(() {
              final currentState = controller.currentState;

              if (currentState == 'loading' ||
                  currentState == 'transcribing' ||
                  currentState == 'summarizing') {
                return _buildProcessingSection(currentState);
              } else if (currentState.startsWith('error')) {
                return _buildErrorSection();
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      _buildContentSection(),
                    ],
                  ),
                );
              }
            }),
          ),
          SessionDebugOverlay(),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 0,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  Widget _buildProcessingSection(String state) {
    String title;
    String description;
    Widget icon;

    switch (state) {
      case 'transcribing':
        title = 'Transcribing Audio';
        description = 'Converting speech to text...';
        icon = CircularProgressIndicator(
          color: appTheme.primary,
          strokeWidth: 3.0,
        );
        break;
      case 'summarizing':
        title = 'Generating Summary';
        description = 'Creating intelligent insights...';
        icon = CircularProgressIndicator(
          color: appTheme.secondary,
          strokeWidth: 3.0,
        );
        break;
      default:
        title = 'Loading';
        description = 'Initializing...';
        icon = CircularProgressIndicator(
          color: appTheme.primary,
          strokeWidth: 3.0,
        );
    }

    return Column(
      children: [
        _buildHeaderSection(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 24.h,
              children: [
                Container(
                  padding: EdgeInsets.all(20.h),
                  decoration: BoxDecoration(
                    color: appTheme.neutral,
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                ),
                Column(
                  spacing: 8.h,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyleHelper.instance.headline24BoldQuattrocento,
                    ),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(color: appTheme.gray_700),
                    ),
                  ],
                ),
                // Progress indicator with estimated time
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 40.h),
                  padding: EdgeInsets.all(16.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_50,
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(color: appTheme.gray_300),
                  ),
                  child: Column(
                    spacing: 8.h,
                    children: [
                      Text(
                        _getEstimatedTime(state),
                        style: TextStyleHelper.instance.body12RegularOpenSans
                            .copyWith(color: appTheme.gray_700),
                      ),
                      LinearProgressIndicator(
                        color: appTheme.primary,
                        backgroundColor: appTheme.gray_200,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getEstimatedTime(String state) {
    switch (state) {
      case 'transcribing':
        return 'Usually takes 30-60 seconds';
      case 'summarizing':
        return 'Usually takes 15-30 seconds';
      default:
        return 'Please wait...';
    }
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        _buildHeaderSection(),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20.h,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48.h,
                    ),
                  ),
                  Text(
                    'Processing Failed',
                    style: TextStyleHelper.instance.headline24BoldQuattrocento
                        .copyWith(color: Colors.red),
                  ),
                  Text(
                    controller.stateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.instance.body14RegularOpenSans
                        .copyWith(color: appTheme.gray_700),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12.h,
                    children: [
                      ElevatedButton(
                        onPressed: () => controller.retry(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.h,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyleHelper.instance.body14SemiBoldOpenSans
                              .copyWith(color: appTheme.white_A700),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: appTheme.gray_300),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.h,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: TextStyleHelper.instance.body14SemiBoldOpenSans
                              .copyWith(color: appTheme.gray_900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        Get.toNamed(Routes.homeScreen);
        break;
      case 1:
        Get.toNamed(Routes.recordingLibraryScreen);
        break;
      case 2:
        Get.toNamed(Routes.settingsScreen);
        break;
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        border: Border(
          bottom: BorderSide(
            color: appTheme.colorE67FDE,
            width: 1.h,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
      child: Column(
        spacing: 22.h,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(left: 10.h, top: 4.h),
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
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            child: Text(
              'Summary & Notes',
              style: TextStyleHelper.instance.title18BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      margin: EdgeInsets.all(16.h),
      child: Column(
        spacing: 16.h,
        children: [
          // Summary section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: appTheme.white_A700,
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(color: appTheme.gray_300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12.h,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize,
                      color: appTheme.primary,
                      size: 20.h,
                    ),
                    SizedBox(width: 8.h),
                    Text(
                      'Summary',
                      style: TextStyleHelper.instance.title16SemiBoldOpenSans
                          .copyWith(color: appTheme.primary),
                    ),
                  ],
                ),
                Obx(() => Text(
                      controller.summaryText,
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(height: 1.43),
                    )),
              ],
            ),
          ),

          // Key Points section
          Obx(() {
            final keyPoints = controller.keyPoints;
            if (keyPoints.isEmpty) return SizedBox.shrink();

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: appTheme.white_A700,
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(color: appTheme.gray_300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12.h,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: appTheme.accentIndigo,
                        size: 20.h,
                      ),
                      SizedBox(width: 8.h),
                      Text(
                        'Key Points',
                        style: TextStyleHelper.instance.title16SemiBoldOpenSans
                            .copyWith(color: appTheme.accentIndigo),
                      ),
                    ],
                  ),
                  ...keyPoints.map((point) => Padding(
                        padding: EdgeInsets.only(left: 8.h, bottom: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "â€¢ ",
                              style: TextStyleHelper
                                  .instance.body14RegularOpenSans
                                  .copyWith(color: appTheme.accentIndigo),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyleHelper
                                    .instance.body14RegularOpenSans
                                    .copyWith(height: 1.43),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),

          // Action Items section
          Obx(() {
            final actionItems = controller.actionItems;
            if (actionItems.isEmpty) return SizedBox.shrink();

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: appTheme.white_A700,
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(color: appTheme.gray_300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12.h,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: appTheme.accentTeal,
                        size: 20.h,
                      ),
                      SizedBox(width: 8.h),
                      Text(
                        'Action Items',
                        style: TextStyleHelper.instance.title16SemiBoldOpenSans
                            .copyWith(color: appTheme.accentTeal),
                      ),
                    ],
                  ),
                  ...actionItems.map((item) => Padding(
                        padding: EdgeInsets.only(left: 8.h, bottom: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              color: appTheme.accentTeal,
                              size: 16.h,
                            ),
                            SizedBox(width: 8.h),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyleHelper
                                    .instance.body14RegularOpenSans
                                    .copyWith(height: 1.43),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),

          // Transcript section with collapsible panel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: appTheme.white_A700,
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(color: appTheme.gray_300),
            ),
            child: Theme(
              data: ThemeData(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: appTheme.gray_700,
                      size: 20.h,
                    ),
                    SizedBox(width: 8.h),
                    Text(
                      'Transcript (raw)',
                      style: TextStyleHelper.instance.title16SemiBoldOpenSans
                          .copyWith(color: appTheme.gray_700),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.h),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.h),
                          decoration: BoxDecoration(
                            color: appTheme.gray_50,
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                          child: Obx(() => Text(
                                controller.rawTranscriptJson,
                                style: TextStyleHelper
                                    .instance.body12RegularOpenSans
                                    .copyWith(fontFamily: 'monospace'),
                              )),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: controller.rawTranscriptJson));
                            Get.snackbar(
                              'Copied',
                              'Transcript copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.gray_700,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.h,
                              vertical: 8.h,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                color: appTheme.white_A700,
                                size: 16.h,
                              ),
                              SizedBox(width: 8.h),
                              Text(
                                'Copy Transcript',
                                style: TextStyleHelper
                                    .instance.body14RegularOpenSans
                                    .copyWith(color: appTheme.white_A700),
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
          ),

          // Action buttons
          _buildActionChipsSection(),
        ],
      ),
    );
  }

  Widget _buildActionChipsSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionChip(
            'Copy All',
            Icons.copy,
            () => _copyAll(),
          ),
          _buildActionChip(
            'Share',
            Icons.share,
            () => _exportShare(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        decoration: BoxDecoration(
          color: appTheme.primary,
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.h,
          children: [
            Icon(
              icon,
              color: appTheme.white_A700,
              size: 16.h,
            ),
            Text(
              label,
              style: TextStyleHelper.instance.body14SemiBoldOpenSans
                  .copyWith(color: appTheme.white_A700),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAll() {
    final summary = controller.summaryText;
    final keyPoints = controller.keyPoints.join('\nâ€¢ ');
    final actionItems = controller.actionItems.join('\nâ€¢ ');

    String combinedText = 'Summary:\n$summary\n\n';

    if (keyPoints.isNotEmpty) {
      combinedText += 'Key Points:\nâ€¢ $keyPoints\n\n';
    }

    if (actionItems.isNotEmpty) {
      combinedText += 'Action Items:\nâ€¢ $actionItems\n\n';
    }

    combinedText += 'Transcript:\n${controller.rawTranscriptJson}';

    Clipboard.setData(ClipboardData(text: combinedText));
    Get.snackbar(
      'Copied',
      'All content copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _exportShare() {
    final summary = controller.summaryText;
    final keyPoints = controller.keyPoints.join('\nâ€¢ ');
    final actionItems = controller.actionItems.join('\nâ€¢ ');

    String shareText = 'Recording Summary:\n$summary\n\n';

    if (keyPoints.isNotEmpty) {
      shareText += 'Key Points:\nâ€¢ $keyPoints\n\n';
    }

    if (actionItems.isNotEmpty) {
      shareText += 'Action Items:\nâ€¢ $actionItems';
    }

    Share.share(shareText, subject: 'Recording Summary');
  }
}
