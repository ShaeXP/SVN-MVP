import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
// lib/presentation/login_screen/login_screen.dart
import 'package:flutter/material.dart';
import 'package:lashae_s_application/widgets/session_debug_overlay.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import './controller/login_controller.dart';

class LoginScreen extends GetWidget<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorder')),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: appTheme.color281E12,
                  offset: Offset(0, 3.h),
                  blurRadius: 6.h,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                CustomAppBar(
                  leadingImagePath: ImageConstant.imgGroup,
                  trailingImagePath: ImageConstant.imgGroupGray900,
                  centerLogoImagePath: ImageConstant.imgImgLogomic54x68,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22.h, 32.h, 22.h, 0),
                      child: Column(
                        children: [
                          _buildLoginForm(),
                          SizedBox(height: 24.h),
                          _buildTryDemoSection(),
                          SizedBox(height: 14.h),
                          _buildDemoAccountInfo(),
                          SizedBox(height: 32.h),
                          _buildOrContinueWithSection(),
                          SizedBox(height: 32.h),
                          _buildGoogleButton(),
                          SizedBox(height: 16.h),
                          _buildMicrosoftButton(),
                          SizedBox(height: 40.h),
                          _buildCreateAccountSection(),
                          SizedBox(height: 38.h),
                          _buildSecuritySection(),
                          SizedBox(height: 44.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SessionDebugOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1.h,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.h, 32.h, 24.h, 32.h),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome Back',
              style: TextStyleHelper.instance.headline30BoldQuattrocento
                  .copyWith(height: 1.13),
            ),
            SizedBox(height: 14.h),
            Text(
              'Sign in to access your voice recordings and AI-powered insights',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title16RegularOpenSans
                  .copyWith(height: 1.5),
            ),
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email Address *',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_900, height: 1.42),
              ),
            ),
            SizedBox(height: 14.h),
            CustomEditText(
              controller: controller.emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
            ),
            SizedBox(height: 16.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password *',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_900, height: 1.42),
              ),
            ),
            SizedBox(height: 14.h),
            CustomEditText(
              controller: controller.passwordController,
              hintText: 'Enter your password',
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              validator: controller.validatePassword,
            ),
            SizedBox(height: 24.h),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => controller.onForgotPasswordTap(),
                child: Text(
                  'Forgot password?',
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.blue_200_01, height: 1.43),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Obx(
              () => CustomButton(
                text: 'Sign In',
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.onSignInTap(),
                backgroundColor: appTheme.blue_200_01,
                textColor: appTheme.cyan_900,
                borderRadius: 10,
                variant: CustomButtonVariant.filled,
                elevation: 1,
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryDemoSection() {
    return Text(
      'Try Demo Login',
      style: TextStyleHelper.instance.body14RegularOpenSans
          .copyWith(color: appTheme.gray_700, height: 1.43),
    );
  }

  Widget _buildDemoAccountInfo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1.h,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Row(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgInfo,
                height: 20.h,
                width: 20.h,
              ),
              SizedBox(width: 12.h),
              Text(
                'Demo Account:',
                style: TextStyleHelper.instance.body14SemiBoldOpenSans
                    .copyWith(height: 1.43),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.only(left: 32.h),
            child: Text(
              'Email: demo@example.com',
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_700, height: 1.43),
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.only(left: 32.h),
            child: Text(
              'Password: demo123',
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_700, height: 1.43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrContinueWithSection() {
    return Row(
      children: [
        Expanded(child: Container(height: 1.h, color: appTheme.gray_300)),
        SizedBox(width: 16.h),
        Text(
          'Or continue with',
          style: TextStyleHelper.instance.body14RegularOpenSans
              .copyWith(color: appTheme.gray_700, height: 1.43),
        ),
        SizedBox(width: 16.h),
        Expanded(child: Container(height: 1.h, color: appTheme.gray_300)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return CustomButton(
      text: 'Continue with Google',
      leftIcon: ImageConstant.imgMessageCircle,
      onPressed: () => controller.onGoogleSignInTap(),
      backgroundColor: appTheme.whiteCustom,
      textColor: appTheme.gray_900,
      borderColor: appTheme.gray_300,
      borderWidth: 1,
      borderRadius: 10,
      variant: CustomButtonVariant.outlined,
      elevation: 1,
      fontSize: 16.fSize,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildMicrosoftButton() {
    return CustomButton(
      text: 'Continue with Microsoft',
      leftIcon: ImageConstant.imgMessageCircle,
      onPressed: () => controller.onMicrosoftSignInTap(),
      backgroundColor: appTheme.whiteCustom,
      textColor: appTheme.gray_900,
      borderColor: appTheme.gray_300,
      borderWidth: 1,
      borderRadius: 10,
      variant: CustomButtonVariant.outlined,
      elevation: 1,
      fontSize: 16.fSize,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildCreateAccountSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyleHelper.instance.body14RegularOpenSans
              .copyWith(color: appTheme.gray_900, height: 1.43),
        ),
        SizedBox(width: 4.h),
        GestureDetector(
          onTap: () => controller.onCreateAccountTap(),
          child: Text(
            'Create Account',
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.blue_200_01, height: 1.43),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.gray_50_01,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            offset: Offset(0, 0),
            blurRadius: 1.h,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(26.h, 20.h, 26.h, 20.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 34.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgShieldCheck,
                  height: 24.h,
                  width: 24.h,
                ),
                SizedBox(
                  height: 22.h,
                  width: 20.h,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: CustomImageView(
                            imagePath: ImageConstant.imgVectorGray90001,
                            height: 8.h,
                            width: 4.h,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 6.h),
                          child: CustomImageView(
                            imagePath: ImageConstant.imgVectorGray9000110x3,
                            height: 10.h,
                            width: 3.h,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: CustomImageView(
                          imagePath: ImageConstant.imgVectorGray900014x2,
                          height: 4.h,
                          width: 2.h,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: 14.h,
                          width: 20.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomImageView(
                                imagePath:
                                    ImageConstant.imgVectorGray9000112x20,
                                height: 12.h,
                                width: 20.h,
                                alignment: Alignment.center,
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: 12.h,
                                  width: 20.h,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant.imgVectorGray900012x2,
                                        height: 2.h,
                                        width: 2.h,
                                      ),
                                      SizedBox(width: 4.h),
                                      CustomImageView(
                                        imagePath: ImageConstant
                                            .imgVectorGray9000110x10,
                                        height: 10.h,
                                        width: 10.h,
                                      ),
                                      CustomImageView(
                                        imagePath:
                                            ImageConstant.imgVectorGray900018x2,
                                        height: 8.h,
                                        width: 2.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 2.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 2.h),
                                child: CustomImageView(
                                  imagePath: ImageConstant.imgVector10x3,
                                  height: 10.h,
                                  width: 3.h,
                                ),
                              ),
                              CustomImageView(
                                imagePath: ImageConstant.imgVector4x2,
                                height: 4.h,
                                width: 2.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgFileTextGray90001,
                  height: 24.h,
                  width: 24.h,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(right: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSL Encrypted',
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900_01, height: 1.43),
                ),
                SizedBox(width: 20.h),
                Text(
                  'Privacy Protected',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900_01, height: 1.43),
                ),
                const Spacer(),
                Text(
                  'GDPR Compliant',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularOpenSans
                      .copyWith(color: appTheme.gray_900_01, height: 1.43),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Your data is secure and protected with enterprise-grade encryption.',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_900_01, height: 1.43),
          ),
        ],
      ),
    );
  }
}
