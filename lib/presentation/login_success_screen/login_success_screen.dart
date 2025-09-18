import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import './controller/login_success_controller.dart';

class LoginSuccessScreen extends GetWidget<LoginSuccessController> {
  const LoginSuccessScreen({Key? key}) : super(key: key);

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
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          spacing: 30.h,
          children: [
            Column(
              spacing: 22.h,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: appTheme.white_A700,
                    border: Border(
                      bottom: BorderSide(
                        color: appTheme.colorE67FDE,
                        width: 1,
                      ),
                    ),
                  ),
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
                      Align(
                        alignment: Alignment.bottomRight,
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
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    'Login Successful',
                    style: TextStyleHelper.instance.title18BoldQuattrocento
                        .copyWith(height: 1.11),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 34.h),
                padding: EdgeInsets.symmetric(horizontal: 34.h, vertical: 26.h),
                decoration: BoxDecoration(
                  color: appTheme.white_A700,
                  borderRadius: BorderRadius.circular(16.h),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.color1F0C17,
                      offset: Offset(0, 0),
                      blurRadius: 1,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      child: CustomImageView(
                        imagePath: ImageConstant.imgGroupGray90072x72,
                        height: 72.h,
                        width: 72.h,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20.h),
                      child: Text(
                        'Login Successful',
                        style: TextStyleHelper
                            .instance.headline24BoldQuattrocento
                            .copyWith(height: 1.125),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10.h),
                      child: Text(
                        'Welcome back to SmartVoiceNotes! You\'re all set to explore.',
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.title16RegularOpenSans
                            .copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.h),
              child: CustomButton(
                text: 'Continue to App',
                onPressed: () => controller.onContinuePressed(),
                backgroundColor: appTheme.blue_200_01,
                textColor: appTheme.cyan_900,
                borderRadius: 10.h,
                variant: CustomButtonVariant.filled,
                fontSize: 14.fSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
