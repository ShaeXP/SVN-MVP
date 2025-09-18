import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import './controller/recording_ready_controller.dart';

// Modified: Fixed incorrect import path

class RecordingReadyScreenInitialPage extends StatelessWidget {
  RecordingReadyScreenInitialPage({Key? key}) : super(key: key);

  RecordingReadyController controller = Get.put(RecordingReadyController());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        boxShadow: [
          BoxShadow(
            color: appTheme.color281E12,
            blurRadius: 6.h,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
        spacing: 20.h,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.h, 12.h, 18.h, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: EdgeInsets.only(top: 4.h, left: 10.h),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgGroup,
                      height: 10.h,
                      width: 26.h,
                    ),
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
            margin: EdgeInsets.only(bottom: 14.h),
            child: Text(
              'Record New Audio',
              style: TextStyleHelper.instance.title18BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTimerSection(),
        _buildWaveformSection(),
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildTimerSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.h, 14.h, 14.h, 16.h),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            blurRadius: 1.h,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        spacing: 4.h,
        children: [
          Obx(() => Text(
                controller.timerDisplay.value,
                style: TextStyleHelper.instance.display60BoldQuattrocento
                    .copyWith(height: 1.12),
              )),
          Container(
            margin: EdgeInsets.only(bottom: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8.h,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgDot,
                  height: 12.h,
                  width: 12.h,
                ),
                Obx(() => Text(
                      controller.statusText.value,
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(color: appTheme.gray_700, height: 1.43),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.h, 0, 14.h, 32.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            blurRadius: 1.h,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: CustomImageView(
        imagePath: ImageConstant.imgGroupBlue200,
        width: double.infinity,
        height: 150.h,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: EdgeInsets.fromLTRB(90.h, 0, 96.h, 0),
      child: Row(
        spacing: 24.h,
        children: [
          GestureDetector(
            onTap: () => controller.onPlayPausePressed(),
            child: Container(
              height: 80.h,
              width: 80.h,
              decoration: BoxDecoration(
                color: appTheme.blue_200_01,
                borderRadius: BorderRadius.circular(40.h),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.color1F0C17,
                    blurRadius: 1.h,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: CustomImageView(
                  imagePath: ImageConstant.imgPlay,
                  height: 36.h,
                  width: 36.h,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.onStopPressed(),
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
