import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/active_recording_controller.dart';

class ActiveRecordingScreen extends StatelessWidget {
  ActiveRecordingScreen({Key? key}) : super(key: key);

  final ActiveRecordingController controller =
      Get.put(ActiveRecordingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        width: double.infinity,
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
        child: Column(
          children: [
            _buildHeaderSection(),
            SizedBox(height: 30.h),
            _buildRecordingDisplaySection(),
            SizedBox(height: 30.h),
            _buildControlButtonsSection(),
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
            width: 1,
          ),
        ),
      ),
      child: Column(
        spacing: 20.h,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(18.h, 12.h, 18.h, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 4.h, left: 10.h),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgGroup,
                      height: 10.h,
                      width: 26.h,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgGroupGray900,
                    height: 10.h,
                    width: 64.h,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 18.h),
            child: Text(
              'Recording in Progress',
              style: TextStyleHelper.instance.title20BoldQuattrocento
                  .copyWith(height: 1.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingDisplaySection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22.h),
      padding: EdgeInsets.all(24.h),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8.h,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.only(bottom: 20.h),
                  height: 12.h,
                  width: 12.h,
                  decoration: BoxDecoration(
                    color: appTheme.color51B5CA,
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                ),
              ),
              Obx(() => Text(
                    controller.recordingTime.value,
                    style: TextStyleHelper.instance.display48BoldQuattrocento
                        .copyWith(letterSpacing: 1, height: 1.125),
                  )),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Active Recording',
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700, height: 1.43),
          ),
          SizedBox(height: 32.h),
          Container(
            height: 120.h,
            width: 294.h,
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: appTheme.gray_50,
              borderRadius: BorderRadius.circular(10.h),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgGroupBlue200110x270,
                  height: 110.h,
                  width: 270.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtonsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 94.h),
      child: Row(
        spacing: 24.h,
        children: [
          GestureDetector(
            onTap: () => controller.pauseRecording(),
            child: Container(
              height: 80.h,
              width: 80.h,
              decoration: BoxDecoration(
                color: appTheme.white_A700,
                border: Border.all(
                  color: appTheme.blue_200_01,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(40.h),
              ),
              child: Center(
                child: CustomImageView(
                  imagePath: ImageConstant.imgPause,
                  height: 14.h,
                  width: 14.h,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.stopRecording(),
              child: Container(
                height: 96.h,
                decoration: BoxDecoration(
                  color: appTheme.red_400,
                  borderRadius: BorderRadius.circular(48.h),
                ),
                child: Center(
                  child: CustomImageView(
                    imagePath: ImageConstant.imgSquare,
                    height: 32.h,
                    width: 32.h,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
