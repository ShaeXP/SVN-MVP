import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import './controller/welcome_controller.dart';

class WelcomeScreen extends GetWidget<WelcomeController> {
  WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: SafeArea(
        child: Container(
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 40.h,
                    left: 24.h,
                    right: 24.h,
                  ),
                  child: Column(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgImgLogomic,
                        width: 280.h,
                        height: 280.h,
                        radius: BorderRadius.circular(10.h),
                      ),
                      SizedBox(height: 36.h),
                      Text(
                        'Welcome to SmartVoiceNotes',
                        style: TextStyleHelper.instance.display36BoldQuattrocento
                            .copyWith(height: 1.11),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your ultimate AI-powered voice companion.',
                        style: TextStyleHelper.instance.title18RegularOpenSans
                            .copyWith(height: 1.39),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 44.h),
                      _buildFeatureRow(
                        'Record instantly and effortlessly',
                      ),
                      SizedBox(height: 16.h),
                      _buildFeatureRow(
                        'AI-powered summaries for quick insights',
                      ),
                      SizedBox(height: 16.h),
                      _buildFeatureRow(
                        'Organize & share your notes easily',
                      ),
                      SizedBox(height: 52.h),
                      GestureDetector(
                        onTap: () {
                          controller.onGetStartedPressed();
                        },
                        child: Text(
                          'Get Started',
                          style: TextStyleHelper.instance.title18SemiBoldOpenSans
                              .copyWith(height: 1.39),
                        ),
                      ),
                      SizedBox(height: 44.h),
                      GestureDetector(
                        onTap: () {
                          controller.onSignInPressed();
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 30.h),
                          child: Text(
                            'Sign In',
                            style: TextStyleHelper.instance.title18SemiBoldOpenSans
                                .copyWith(
                                    color: appTheme.blue_gray_900, height: 1.39),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18.h,
          height: 18.h,
          decoration: BoxDecoration(
            color: appTheme.blue_200_01,
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Center(
            child: CustomImageView(
              imagePath: ImageConstant.imgIconCheck1,
              width: 6.h,
              height: 4.h,
            ),
          ),
        ),
        SizedBox(width: 12.h),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyleHelper.instance.title16RegularOpenSans
                  .copyWith(color: appTheme.gray_900, height: 1.38),
            ),
          ),
        ),
      ],
    );
  }
}
