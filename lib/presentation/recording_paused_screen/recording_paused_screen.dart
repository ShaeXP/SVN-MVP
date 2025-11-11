import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_paused_controller.dart';

class RecordingPausedScreen extends StatelessWidget {
  RecordingPausedScreen({Key? key}) : super(key: key);

  // Controller is registered via binding
  RecordingPausedController get controller => Get.find<RecordingPausedController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: appTheme.white_A700,
              border: Border(
                bottom: BorderSide(
                  color: appTheme.color7FDEE1,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.color281E12,
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              spacing: 20.h,
              children: [
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          bottom: 12.h,
                          left: 28.w,
                        ),
                        child: CustomImageView(
                          imagePath: ImageConstant.imgGroup,
                          height: 10.h,
                          width: 26.w,
                        ),
                      ),
                      CustomImageView(
                        imagePath: ImageConstant.imgImageGray900,
                        height: 40.h,
                        width: 94.w,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    right: 24.w,
                    bottom: 12.h,
                    left: 24.w,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Recording Paused',
                          style: TextStyleHelper
                              .instance.title18BoldQuattrocento
                              .copyWith(height: 1.11),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 74.w),
                        child: CustomImageView(
                          imagePath: ImageConstant.imgSettings,
                          height: 22.h,
                          width: 22.w,
                          onTap: () {
                            Get.toNamed(Routes.settings, id: 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    top: 22.h,
                    right: 22.w,
                    left: 22.w,
                  ),
                  padding: EdgeInsets.all(24.w),
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
                      Container(
                        child: Row(
                          spacing: 8.w,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 22.h),
                              height: 8.h,
                              width: 8.w,
                              decoration: BoxDecoration(
                                color: appTheme.gray_700,
                                borderRadius: BorderRadius.circular(4.h),
                              ),
                            ),
                            Obx(() => Text(
                                  "00:00:00",
                                  style: TextStyleHelper
                                      .instance.display48BoldQuattrocento
                                      .copyWith(height: 1.125),
                                )),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Paused Recording',
                        style: TextStyleHelper
                            .instance.title18RegularOpenSans
                            .copyWith(height: 1.39),
                      ),
                      SizedBox(height: 36.h),
                      CustomImageView(
                        imagePath: ImageConstant.imgGroupBlue20084x290,
                        height: 84.h,
                        width: 290.w,
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),
                Container(
                  child: Row(
                    spacing: 16.w,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.onResumePressed();
                        },
                        child: Container(
                          height: 80.h,
                          width: 80.w,
                          decoration: BoxDecoration(
                            color: appTheme.blue_200_01,
                            borderRadius: BorderRadius.circular(40.h),
                            boxShadow: [
                              BoxShadow(
                                color: appTheme.color1F0C17,
                                offset: Offset(0, 0),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomImageView(
                              imagePath: ImageConstant.imgPlay,
                              height: 40.h,
                              width: 40.w,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.onStopPressed();
                        },
                        child: Container(
                          height: 96.h,
                          width: 96.w,
                          decoration: BoxDecoration(
                            color: appTheme.red_400,
                            borderRadius: BorderRadius.circular(48.h),
                          ),
                          child: Center(
                            child: CustomImageView(
                              imagePath: ImageConstant.imgVectorWhiteA700,
                              height: 26.h,
                              width: 26.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 42.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 48.w),
                  child: Text(
                    'Your current recording is paused. Tap play to resume or stop to save your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.instance.body14RegularOpenSans
                        .copyWith(color: appTheme.gray_700, height: 1.43),
                  ),
                ),
                SizedBox(height: 196.h),
                Container(
                  height: 1.h,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8.h),
                  color: appTheme.gray_200,
                ),
              ],
            ),
          ),
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

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        Get.toNamed(Routes.home, id: 1);
        break;
      case 1:
        Get.toNamed(Routes.recordingLibrary, id: 1);
        break;
      case 2:
        Get.toNamed(Routes.settings, id: 1);
        break;
    }
  }
}
