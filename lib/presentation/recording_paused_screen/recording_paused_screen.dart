import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_paused_controller.dart';

class RecordingPausedScreen extends StatelessWidget {
  RecordingPausedScreen({Key? key}) : super(key: key);

  final RecordingPausedController controller =
      Get.put(RecordingPausedController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        width: double.infinity,
        child: Column(
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
                            left: 28.h,
                          ),
                          child: CustomImageView(
                            imagePath: ImageConstant.imgGroup,
                            height: 10.h,
                            width: 26.h,
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgImageGray900,
                          height: 40.h,
                          width: 94.h,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      right: 24.h,
                      bottom: 12.h,
                      left: 24.h,
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
                          margin: EdgeInsets.only(left: 74.h),
                          child: CustomImageView(
                            imagePath: ImageConstant.imgSettings,
                            height: 22.h,
                            width: 22.h,
                            onTap: () {
                              Get.toNamed(AppRoutes.settingsScreen);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        top: 22.h,
                        right: 22.h,
                        left: 22.h,
                      ),
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
                          Container(
                            child: Row(
                              spacing: 8.h,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 22.h),
                                  height: 8.h,
                                  width: 8.h,
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
                            width: 290.h,
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Container(
                      child: Row(
                        spacing: 16.h,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.onResumePressed();
                            },
                            child: Container(
                              height: 80.h,
                              width: 80.h,
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
                                  width: 40.h,
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
                              width: 96.h,
                              decoration: BoxDecoration(
                                color: appTheme.red_400,
                                borderRadius: BorderRadius.circular(48.h),
                              ),
                              child: Center(
                                child: CustomImageView(
                                  imagePath: ImageConstant.imgVectorWhiteA700,
                                  height: 26.h,
                                  width: 26.h,
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
                      padding: EdgeInsets.symmetric(horizontal: 48.h),
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
}