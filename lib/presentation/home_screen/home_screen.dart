import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/recording_store.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/home_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.white_A700,
        body: Container(
          decoration: BoxDecoration(
            color: appTheme.white_A700,
            boxShadow: [
              BoxShadow(
                color: appTheme.color281E12,
                offset: Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                SizedBox(height: 18.h),
                _buildWelcomeSection(),
                SizedBox(height: 44.h),
                _buildRecordingSection(),
                SizedBox(height: 72.h),
                _buildEmptyStateSection(),
                SizedBox(height: 194.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomBar(
          selectedIndex: 0,
          onChanged: (index) {
            _onBottomNavigationChanged(index);
          },
        ),
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        // Already on Home Screen
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
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        border: Border(
          bottom: BorderSide(
            color: appTheme.colorE67FDE,
            width: 1,
          ),
        ),
      ),
      child: Column(
        spacing: 12.h,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(18.h, 12.h, 18.h, 12.h),
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
          Container(
            margin: EdgeInsets.fromLTRB(16.h, 0, 16.h, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Spacer(),
                Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    'SmartVoiceNotes',
                    style: TextStyleHelper.instance.title18BoldQuattrocento,
                  ),
                ),
                Spacer(),
                CustomImageView(
                  imagePath: ImageConstant.imgIconBell,
                  height: 22.h,
                  width: 22.h,
                ),
                Container(
                  margin: EdgeInsets.only(left: 16.h),
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                    color: appTheme.cyan_50,
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgRectangle,
                        height: 36.h,
                        width: 36.h,
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
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.only(left: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 304.h,
            child: Text(
              'Welcome to SmartVoiceNotes',
              style: TextStyleHelper.instance.display36BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: 326.h,
            margin: EdgeInsets.only(left: 2.h),
            child: Text(
              'Your intelligent assistant for voice-to-text notes.',
              style: TextStyleHelper.instance.title16RegularOpenSans
                  .copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          spacing: 20.h,
          children: [
            Text(
              '00:00:00',
              style: TextStyleHelper.instance.display48BoldQuattrocento
                  .copyWith(height: 1.13),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10.h),
              width: 240.h,
              child: Row(
                spacing: 24.h,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Generate recordingId when starting recording
                      final recordingId =
                          DateTime.now().millisecondsSinceEpoch.toString();

                      // Store in RecordingStore
                      RecordingStore.instance.setCurrentId(recordingId);

                      // Navigate to Active Recording Screen with recordingId
                      Get.toNamed(
                        AppRoutes.activeRecordingScreen,
                        arguments: {'recordingId': recordingId},
                      );
                    },
                    child: Container(
                      height: 96.h,
                      width: 96.h,
                      decoration: BoxDecoration(
                        color: appTheme.blue_200_01,
                        borderRadius: BorderRadius.circular(48.h),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomImageView(
                            imagePath: ImageConstant.imgMic,
                            height: 40.h,
                            width: 40.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 96.h,
                    width: 96.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_200_01,
                      borderRadius: BorderRadius.circular(48.h),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgUpload,
                          height: 40.h,
                          width: 40.h,
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
    );
  }

  Widget _buildEmptyStateSection() {
    return Column(
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgImgEmptystate,
          height: 192.h,
          width: 192.h,
        ),
        SizedBox(height: 28.h),
        Text(
          'No recordings yet',
          style: TextStyleHelper.instance.headline24BoldQuattrocento
              .copyWith(height: 1.13),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 42.h),
          child: Text(
            'Start capturing your ideas and memories with a single tap!',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16RegularOpenSans
                .copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}