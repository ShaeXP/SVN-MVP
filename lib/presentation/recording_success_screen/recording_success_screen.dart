import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_success_controller.dart';

class RecordingSuccessScreen extends GetWidget<RecordingSuccessController> {
  const RecordingSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          spacing: 14.h,
          children: [
            Expanded(
              child: Column(
                spacing: 12.h,
                children: [
                  _buildHeaderSection(),
                  _buildSuccessMessageSection(),
                ],
              ),
            ),
            _buildGoToSummaryButton(),
            _buildBottomNavigationSection(),
          ],
        ),
      ),
    );
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
      child: Column(
        spacing: 12.h,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
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
            margin: EdgeInsets.only(left: 16.h, right: 16.h, bottom: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 138.h),
                  child: Text(
                    'Recorder',
                    style: TextStyleHelper.instance.title18MediumInter
                        .copyWith(height: 1.22),
                  ),
                ),
                Container(
                  width: 36.h,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: appTheme.cyan_50_01,
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                  child: Stack(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgRectangle36x36,
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

  Widget _buildSuccessMessageSection() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 74.h),
        padding: EdgeInsets.all(30.h),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 14.h,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 42.h,
              height: 42.h,
              child: Stack(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgVectorGreen600,
                    height: 42.h,
                    width: 42.h,
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: EdgeInsets.only(top: 2.h),
                      child: CustomImageView(
                        imagePath: ImageConstant.imgVectorGreen60022x28,
                        height: 22.h,
                        width: 28.h,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => controller.isProcessing.value
                ? Column(
                    spacing: 12.h,
                    children: [
                      CircularProgressIndicator(
                        color: appTheme.blue_A700,
                        strokeWidth: 2.h,
                      ),
                      Text(
                        controller.processingStatus.value,
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.body14RegularOpenSans
                            .copyWith(
                          color: appTheme.gray_700,
                          height: 1.43,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Recording successfully saved.',
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.instance.title16MediumInter
                        .copyWith(height: 1.38),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoToSummaryButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
      width: double.infinity,
      child: Obx(() => ElevatedButton(
            onPressed: controller.isProcessing.value
                ? null
                : controller.onGoToSummaryPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isProcessing.value
                  ? appTheme.gray_500
                  : appTheme.blue_A700,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.h),
              ),
            ),
            child: Text(
              controller.isProcessing.value ? 'Processing...' : 'Go to Summary',
              style: TextStyleHelper.instance.title16SemiBoldOpenSans
                  .copyWith(color: appTheme.white_A700),
            ),
          )),
    );
  }

  Widget _buildBottomNavigationSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageConstant.imgContainerGray200),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomBottomBar(
            selectedIndex: 0,
            onChanged: (index) {
              controller.onBottomNavigationChanged(index);
            },
          ),
        ],
      ),
    );
  }
}