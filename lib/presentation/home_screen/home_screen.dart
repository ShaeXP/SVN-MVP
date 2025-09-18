import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
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
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              // use width-based padding for horizontal spacing
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildWelcomeSection(context),
                  SizedBox(height: 24.h),
                  _buildRecordingSection(context),
                  SizedBox(height: 32.h),
                  _buildEmptyStateSection(context),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomBar(
          selectedIndex: 0,
          onChanged: (index) => _onBottomNavigationChanged(index),
        ),
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        break; // already on Home
      case 1:
        Get.toNamed(Routes.recordingLibraryScreen);
        break;
      case 2:
        Get.toNamed(Routes.settingsScreen);
        break;
    }
  }

  // --- Sections ---

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome to SmartVoiceNotes',
          style: Theme.of(context).textTheme.displayMedium, // deep navy heading
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        Text(
          'Your intelligent assistant for voice-to-text notes.',
          style: Theme.of(context).textTheme.bodyMedium, // muted body
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: const Offset(0, 0),
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          children: [
            Text('00:00', style: Theme.of(context).textTheme.displayMedium),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.recordingReadyScreenInitialPage),
                  child: Container(
                    height: 96.h,
                    width: 96.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_200_01,
                      borderRadius: BorderRadius.circular(48.h),
                    ),
                    child: Center(
                      child: CustomImageView(
                        imagePath: ImageConstant.imgMic,
                        height: 40.h,
                        width: 40.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24.h),
                // Upload
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.recordingLibraryScreen),
                  child: Container(
                    height: 96.h,
                    width: 96.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_200_01,
                      borderRadius: BorderRadius.circular(48.h),
                    ),
                    child: Center(
                      child: CustomImageView(
                        imagePath: ImageConstant.imgUpload,
                        height: 40.h,
                        width: 40.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateSection(BuildContext context) {
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
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.h),
          child: Text(
            'Start capturing your ideas and memories with a single tap!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
