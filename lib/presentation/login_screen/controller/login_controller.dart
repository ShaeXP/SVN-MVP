import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../models/login_model.dart';

class LoginController extends GetxController {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late GlobalKey<FormState> formKey;

  RxBool isLoading = false.obs;
  RxBool isEmailValid = false.obs;
  RxBool isPasswordValid = false.obs;
  Rx<LoginModel?> loginModel = Rx<LoginModel?>(null);

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    loginModel.value = LoginModel();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      isEmailValid.value = false;
      return 'Email is required';
    }

    final emailRegExp =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      isEmailValid.value = false;
      return 'Please enter a valid email address';
    }

    isEmailValid.value = true;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      isPasswordValid.value = false;
      return 'Password is required';
    }

    if (value.length < 6) {
      isPasswordValid.value = false;
      return 'Password must be at least 6 characters';
    }

    isPasswordValid.value = true;
    return null;
  }

  void onSignInPressed() async {
    if (!_validateForm()) return;

    isLoading.value = true;
    try {
      final response = await SupabaseService.instance.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        Get.offAllNamed(AppRoutes.homeScreen);
        Get.snackbar(
          'Success',
          'Welcome back!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.green_600,
          colorText: appTheme.white_A700,
        );
      }
    } catch (error) {
      Get.snackbar(
        'Sign In Failed',
        error.toString().replaceAll('Exception: Sign in failed: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSignUpPressed() async {
    if (!_validateForm()) return;

    isLoading.value = true;
    try {
      final response = await SupabaseService.instance.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: 'User', // Default name, can be updated later
      );

      if (response.user != null) {
        Get.snackbar(
          'Success',
          'Account created successfully! Please check your email for verification.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.green_600,
          colorText: appTheme.white_A700,
        );
      }
    } catch (error) {
      Get.snackbar(
        'Sign Up Failed',
        error.toString().replaceAll('Exception: Sign up failed: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter your email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter your password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 6 characters long',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
      return false;
    }

    return true;
  }

  void onSignInTap() async {
    if (formKey.currentState?.validate() == true) {
      try {
        isLoading.value = true;

        // Simulate API call
        await Future.delayed(Duration(seconds: 2));

        // Check demo credentials
        if (emailController.text == 'demo@example.com' &&
            passwordController.text == 'demo123') {
          Get.snackbar(
            'Success',
            'Demo login successful!',
            backgroundColor: appTheme.greenCustom,
            colorText: appTheme.whiteCustom,
            snackPosition: SnackPosition.TOP,
          );

          // Clear form fields
          emailController.clear();
          passwordController.clear();

          // Navigate to home screen
          Get.offAllNamed(AppRoutes.homeScreen);
        } else {
          // Regular login validation
          if (isEmailValid.value && isPasswordValid.value) {
            Get.snackbar(
              'Success',
              'Login successful!',
              backgroundColor: appTheme.greenCustom,
              colorText: appTheme.whiteCustom,
              snackPosition: SnackPosition.TOP,
            );

            // Clear form fields
            emailController.clear();
            passwordController.clear();

            // Navigate to login success screen
            Get.offAllNamed(AppRoutes.loginSuccessScreen);
          }
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Login failed. Please try again.',
          backgroundColor: appTheme.redCustom,
          colorText: appTheme.whiteCustom,
          snackPosition: SnackPosition.TOP,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  void onForgotPasswordTap() {
    Get.snackbar(
      'Info',
      'Forgot password functionality will be implemented',
      backgroundColor: appTheme.blueCustom,
      colorText: appTheme.whiteCustom,
      snackPosition: SnackPosition.TOP,
    );
  }

  void onGoogleSignInTap() {
    Get.snackbar(
      'Info',
      'Google sign-in functionality will be implemented',
      backgroundColor: appTheme.blueCustom,
      colorText: appTheme.whiteCustom,
      snackPosition: SnackPosition.TOP,
    );
  }

  void onMicrosoftSignInTap() {
    Get.snackbar(
      'Info',
      'Microsoft sign-in functionality will be implemented',
      backgroundColor: appTheme.blueCustom,
      colorText: appTheme.whiteCustom,
      snackPosition: SnackPosition.TOP,
    );
  }

  void onCreateAccountTap() {
    Get.toNamed(AppRoutes.welcomeScreen);
  }
}
