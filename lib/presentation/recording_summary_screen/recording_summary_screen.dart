import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:share_plus/share_plus.dart'; // Add this import

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_summary_controller.dart';
import './widgets/summary_length_option_widget.dart';

class RecordingSummaryScreen extends StatelessWidget {
  RecordingSummaryScreen({Key? key}) : super(key: key);

  final RecordingSummaryController controller =
      Get.put(RecordingSummaryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: appTheme.color281E12,
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Obx(() => controller.currentRecording.value == null
            ? _buildLoadingSection()
            : controller.currentRecording.value?.summaryText?.isEmpty ?? true
                ? _buildErrorSection()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeaderSection(),
                        _buildViewTranscriptLink(),
                        _buildRecordingInfoCard(),
                        _buildSummarySection(),
                        _buildActionsSection(),
                        _buildKeyPointsSection(),
                        _buildActionChipsSection(),
                        _buildFooterLine(),
                      ],
                    ),
                  )),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 0,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16.h,
        children: [
          CircularProgressIndicator(
            color: appTheme.blue_A700,
          ),
          Text(
            'Loading recording summary...',
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16.h,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgImgEmptystate,
              height: 120.h,
              width: 120.h,
            ),
            Text(
              'Unable to Load Recording',
              style: TextStyleHelper.instance.title16SemiBoldOpenSans,
            ),
            Text(
              'Recording data could not be found or loaded',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_700),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.blue_A700,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.h,
                  vertical: 12.h,
                ),
              ),
              child: Text(
                'Go Back',
                style: TextStyleHelper.instance.body14SemiBoldOpenSans
                    .copyWith(color: appTheme.white_A700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
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
              'Summary + Actions',
              style: TextStyleHelper.instance.title18BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTranscriptLink() {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerRight,
      margin: EdgeInsets.only(right: 24.h),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to transcript view
          Get.snackbar(
            'Feature Coming Soon',
            'Transcript view will be available in the next update',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: appTheme.blue_A700,
            colorText: appTheme.white_A700,
          );
        },
        child: Text(
          'View Transcript',
          style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
              color: appTheme.blue_A200,
              height: 1.42,
              decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  Widget _buildRecordingInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgIconCalendar,
            height: 16.h,
            width: 16.h,
          ),
          Container(
            margin: EdgeInsets.only(left: 8.h, top: 4.h),
            child: Obx(() => Text(
                  controller.currentRecording.value?.date ?? '',
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900, height: 1.43),
                )),
          ),
          Container(
            margin: EdgeInsets.only(left: 16.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgIconClock,
              height: 16.h,
              width: 16.h,
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 8.h),
            child: Obx(() => Text(
                  controller.currentRecording.value?.duration ?? '',
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900, height: 1.43),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.h, 8.h, 14.h, 0),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(4.h, 20.h, 4.h, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 10.h, top: 6.h),
            child: Text(
              'Summary',
              style: TextStyleHelper.instance.title16BoldQuattrocento
                  .copyWith(height: 1.13),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(10.h, 6.h, 10.h, 0),
            height: 1.h,
            color: appTheme.gray_300,
          ),
          Container(
            margin: EdgeInsets.only(left: 10.h, top: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgIconAi,
                  height: 20.h,
                  width: 20.h,
                ),
                Container(
                  margin: EdgeInsets.only(left: 12.h),
                  child: Text(
                    'AI-generated summary of your recording',
                    style: TextStyleHelper.instance.body14RegularOpenSans
                        .copyWith(color: appTheme.gray_700, height: 1.43),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 2.h),
            child: Row(
              spacing: 8.h,
              children: [
                Expanded(
                  child: SummaryLengthOptionWidget(
                    title: 'Brief',
                    subtitle: '2-3 sentences',
                    isSelected: false,
                    onTap: () => {},
                  ),
                ),
                Expanded(
                  child: SummaryLengthOptionWidget(
                    title: 'Medium',
                    subtitle: '1-2 paragraphs',
                    isSelected: true,
                    onTap: () => {},
                  ),
                ),
                Expanded(
                  child: SummaryLengthOptionWidget(
                    title: 'Detailed',
                    subtitle: '3-4 paragraphs',
                    isSelected: false,
                    onTap: () => {},
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: MediaQuery.of(Get.context!).size.width * 0.9,
            child: Obx(() => Text(
                  controller.currentRecording.value?.summaryText ?? '',
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900, height: 1.64),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.h, 16.h, 14.h, 0),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14.h, 10.h, 14.h, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.h),
            child: Text(
              'Actions',
              style: TextStyleHelper.instance.title18BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 12.h),
            height: 1.h,
            color: appTheme.gray_300,
          ),
          Container(
            margin: EdgeInsets.only(top: 12.h),
            child: Obx(() => Column(
                  children: (controller.currentRecording.value?.actions ?? [])
                      .map((action) => Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    "• ",
                                    style: TextStyleHelper
                                        .instance.body14RegularOpenSans
                                        .copyWith(color: appTheme.blue_A700),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: TextStyleHelper
                                        .instance.body14RegularOpenSans
                                        .copyWith(
                                            color: appTheme.gray_900,
                                            height: 1.43),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointsSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.h, 16.h, 14.h, 0),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16.h, 10.h, 16.h, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Points',
            style: TextStyleHelper.instance.title16SemiBoldOpenSans
                .copyWith(height: 1.38),
          ),
          Container(
            margin: EdgeInsets.only(top: 6.h),
            child: Obx(() => Column(
                  children: (controller.currentRecording.value?.keypoints ?? [])
                      .map((keypoint) => Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    "• ",
                                    style: TextStyleHelper
                                        .instance.body14RegularOpenSans
                                        .copyWith(color: appTheme.blue_A700),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    keypoint,
                                    style: TextStyleHelper
                                        .instance.body14RegularOpenSans
                                        .copyWith(
                                            color: appTheme.gray_900,
                                            height: 1.43),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                )),
          ),
          Container(
            margin: EdgeInsets.only(left: 6.h, top: 14.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgGroupBlue20001,
              height: 2.h,
              width: 2.h,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20.h, bottom: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated with AI transcription and analysis',
                  style: TextStyleHelper.instance.body12RegularOpenSans
                      .copyWith(color: appTheme.gray_700, height: 1.42),
                ),
                Text(
                  DateTime.now().hour > 12
                      ? '${DateTime.now().hour - 12}:${DateTime.now().minute.toString().padLeft(2, '0')} PM'
                      : '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} AM',
                  style: TextStyleHelper.instance.body12RegularOpenSans
                      .copyWith(color: appTheme.gray_700, height: 1.42),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChipsSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(48.h, 16.h, 30.h, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionChip(
            'Copy Summary',
            ImageConstant.imgIconcopy,
            () => _copySummaryAndActions(),
          ),
          _buildActionChip(
            'Copy Actions',
            ImageConstant.imgIconcopy,
            () => _copyActions(),
          ),
          _buildActionChip(
            'Share',
            ImageConstant.imgUpload,
            () => _exportShare(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: appTheme.gray_300),
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4.h,
          children: [
            CustomImageView(
              imagePath: iconPath,
              height: 16.h,
              width: 16.h,
            ),
            Text(
              label,
              style: TextStyleHelper.instance.body12RegularOpenSans
                  .copyWith(color: appTheme.gray_900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLine() {
    return Container(
      margin: EdgeInsets.only(top: 54.h),
      height: 1.h,
      width: double.infinity,
      color: appTheme.gray_200,
    );
  }

  void _copySummaryAndActions() {
    final summary = controller.currentRecording.value?.summaryText ?? '';
    final actions = (controller.currentRecording.value?.actions ?? []).join('\n• ');
    final combinedText = 'Summary:\n$summary\n\nActions:\n• $actions';
    
    Clipboard.setData(ClipboardData(text: combinedText));
    Get.snackbar(
      'Copied',
      'Summary and actions copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _copyActions() {
    final actions = (controller.currentRecording.value?.actions ?? []).join('\n• ');
    final actionsText = 'Actions:\n• $actions';
    
    Clipboard.setData(ClipboardData(text: actionsText));
    Get.snackbar(
      'Copied',
      'Actions copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _exportShare() {
    final summary = controller.currentRecording.value?.summaryText ?? '';
    final actions = (controller.currentRecording.value?.actions ?? []).join('\n• ');
    final keypoints = (controller.currentRecording.value?.keypoints ?? []).join('\n• ');
    
    final shareText = 'Recording Summary:\n$summary\n\nActions:\n• $actions\n\nKey Points:\n• $keypoints';
    
    Share.share(shareText, subject: 'Recording Summary');
  }
}