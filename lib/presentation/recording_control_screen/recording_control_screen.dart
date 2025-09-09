import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_control_controller.dart';

class RecordingControlScreen extends GetWidget<RecordingControlController> {
  RecordingControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appTheme.white_A700,
        body: Container(
            width: double.infinity,
            height: 852.h,
            child: Stack(alignment: Alignment.center, children: [
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
                                    'Your main app content would go here.',
                                    style: TextStyleHelper
                                        .instance.title16RegularOpenSans
                                        .copyWith(height: 1.38))),
                            SizedBox(height: 256.h),
                            Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(left: 46.h),
                                child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: GestureDetector(
                                        onTap: () {
                                          // Navigate directly to Recording Control Screen
                                          Get.toNamed(
                                              AppRoutes.recordingControlScreen);
                                        },
                                        child: Text(
                                            'Tap to Navigate to Recording Control',
                                            style: TextStyleHelper
                                                .instance.body14RegularOpenSans
                                                .copyWith(
                                                    color: appTheme.blue_200_01,
                                                    height: 1.43))))),
                          ]))),

              // Overlay content with header and bottom sheet
              Opacity(
                  opacity: 0.8,
                  child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: appTheme.white_A700,
                      child: Column(children: [
                        // Custom header section
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: appTheme.white_A700,
                                border: Border(
                                    bottom: BorderSide(
                                        color: appTheme.color7FDEE1,
                                        width: 1.h))),
                            child: Column(children: [
                              // Status bar section with icons
                              Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18.h, vertical: 12.h),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                            margin: EdgeInsets.only(
                                                top: 4.h, left: 10.h),
                                            child: CustomImageView(
                                                imagePath:
                                                    ImageConstant.imgGroup,
                                                height: 10.h,
                                                width: 26.h)),
                                        CustomImageView(
                                            imagePath:
                                                ImageConstant.imgGroupGray900,
                                            height: 10.h,
                                            width: 64.h),
                                      ])),

                              // Header with title, bell icon, and profile
                              Container(
                                  width: double.infinity,
                                  margin:
                                      EdgeInsets.fromLTRB(16.h, 0, 16.h, 10.h),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Spacer(),
                                        Container(
                                            margin:
                                                EdgeInsets.only(bottom: 4.h),
                                            child: Text('Recorder',
                                                style: TextStyleHelper.instance
                                                    .title18BoldQuattrocento
                                                    .copyWith(height: 1.11))),
                                        Spacer(),
                                        CustomImageView(
                                            imagePath:
                                                ImageConstant.imgIconBell,
                                            height: 22.h,
                                            width: 22.h),
                                        Container(
                                            height: 36.h,
                                            width: 36.h,
                                            margin: EdgeInsets.only(left: 16.h),
                                            decoration: BoxDecoration(
                                                color: appTheme.deep_purple_50,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        18.h)),
                                            child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CustomImageView(
                                                      imagePath: ImageConstant
                                                          .imgRectangle1,
                                                      height: 36.h,
                                                      width: 36.h,
                                                      fit: BoxFit.cover,
                                                      radius:
                                                          BorderRadius.circular(
                                                              18.h)),
                                                ])),
                                      ])),
                            ])),

                        Spacer(),

                        // Bottom sheet section
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: appTheme.white_A700,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16.h),
                                    topRight: Radius.circular(16.h)),
                                boxShadow: [
                                  BoxShadow(
                                      color: appTheme.color1F0C17,
                                      blurRadius: 1,
                                      offset: Offset(0, 0)),
                                ]),
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Handle indicator
                                  CustomImageView(
                                      imagePath: ImageConstant.imgLine,
                                      height: 4.h,
                                      width: 48.h),

                                  SizedBox(height: 18.h),

                                  // Title
                                  Text('Stop recording?',
                                      style: TextStyleHelper
                                          .instance.title20BoldQuattrocento
                                          .copyWith(height: 1.15)),

                                  SizedBox(height: 4.h),

                                  // Subtitle
                                  Text(
                                      'Choose an option to manage your recording.',
                                      style: TextStyleHelper
                                          .instance.body14RegularOpenSans
                                          .copyWith(
                                              color: appTheme.gray_700,
                                              height: 1.43)),

                                  SizedBox(height: 18.h),

                                  // Recording time
                                  Text('00:05:32',
                                      style: TextStyleHelper
                                          .instance.title18RegularOpenSans
                                          .copyWith(height: 1.39)),

                                  SizedBox(height: 22.h),

                                  // Save button
                                  Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                          onPressed: () {
                                            controller.onSavePressed();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  appTheme.blue_200_01,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 30.h,
                                                  vertical: 12.h),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.h)),
                                              elevation: 0),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CustomImageView(
                                                    imagePath:
                                                        ImageConstant.imgSave,
                                                    height: 20.h,
                                                    width: 20.h),
                                                SizedBox(width: 8.h),
                                                Text('Save',
                                                    style: TextStyleHelper
                                                        .instance
                                                        .body14RegularOpenSans
                                                        .copyWith(
                                                            color: appTheme
                                                                .cyan_900,
                                                            height: 1.43)),
                                              ]))),

                                  SizedBox(height: 12.h),

                                  // Redo button
                                  Container(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                          onPressed: () {
                                            controller.onRedoPressed();
                                          },
                                          style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  appTheme.white_A700,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 30.h,
                                                  vertical: 12.h),
                                              side: BorderSide(
                                                  color: appTheme.red_400,
                                                  width: 1.h),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.h)),
                                              elevation: 0),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CustomImageView(
                                                    imagePath:
                                                        ImageConstant.imgRedo2,
                                                    height: 20.h,
                                                    width: 20.h),
                                                SizedBox(width: 8.h),
                                                Text('Redo',
                                                    style: TextStyleHelper
                                                        .instance
                                                        .body14RegularOpenSans
                                                        .copyWith(
                                                            color: appTheme
                                                                .red_400,
                                                            height: 1.43)),
                                              ]))),

                                  SizedBox(height: 24.h),

                                  // Cancel button
                                  GestureDetector(
                                      onTap: () {
                                        controller.onCancelPressed();
                                      },
                                      child: Text('Cancel',
                                          style: TextStyleHelper
                                              .instance.body14RegularOpenSans
                                              .copyWith(
                                                  color: appTheme.gray_700,
                                                  height: 1.43))),
                                ])),
                      ]))),
            ])),
        bottomNavigationBar: CustomBottomBar(
          selectedIndex: 0,
          onChanged: (index) {
            _onBottomNavigationChanged(index);
          },
        ));
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
