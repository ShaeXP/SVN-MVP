import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
// lib/presentation/login_screen/controller/login_controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // LOGIN-FIRST: Added for direct Supabase auth
import 'package:lashae_s_application/services/supabase_service.dart';
import '../../../core/app_export.dart';
import '../models/login_model.dart';
import '../../../app/navigation/bottom_nav_controller.dart';
import '../../home_screen/controller/home_controller.dart';

class LoginController extends GetxController {
  // Form + fields
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final GlobalKey<FormState> formKey;

  // State
  final RxBool isLoading = false.obs;
  final RxBool isEmailValid = false.obs;
  final RxBool isPasswordValid = false.obs;
  final Rx<LoginModel?> loginModel = Rx<LoginModel?>(null);

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

  // ----------- Validation -----------
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

  bool _validateForm() {
    final ok = formKey.currentState?.validate() ?? false;
    if (!ok) {
      Get.snackbar(
        'Validation Error',
        'Please fix the highlighted fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appTheme.red_400,
        colorText: appTheme.white_A700,
      );
    }
    return ok;
  }

  // ----------- Auth actions -----------
  Future<void> onSignInPressed() async {
    if (!_validateForm()) return;

    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.session != null) {
        // Navigate to the shell (home tab)
        Get.offAllNamed(Routes.root);
        
        // Temporary verification asserts
        assert(Get.isRegistered<BottomNavController>(), 'BottomNavController not registered');
        assert(Get.isRegistered<HomeController>(), 'HomeController not registered');
      } else {
        // Defensive: show inline error
        _showError('Sign-in failed. No session returned.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // LOGIN-FIRST: Show inline error instead of snackbar
  void _showError(String message) {
    // For now, use snackbar but this could be changed to inline error display
    Get.snackbar(
      'Sign In Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.red_400,
      colorText: appTheme.white_A700,
    );
  }

  Future<void> onSignUpPressed() async {
    if (!_validateForm()) return;

    isLoading.value = true;
    try {
      final response = await SupabaseService.instance.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: 'User',
      );

      if (response.user != null) {
        Get.snackbar(
          'Success',
          'Account created! Check your email for verification.',
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

  // ----------- Handlers expected by the Screen -----------
  void onForgotPasswordTap() {
    Get.snackbar(
      'Info',
      'Forgot password will be implemented.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> onSignInTap() async {
    await onSignInPressed();
  }

  void onGoogleSignInTap() {
    Get.snackbar(
      'Info',
      'Google sign-in will be implemented.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onMicrosoftSignInTap() {
    Get.snackbar(
      'Info',
      'Microsoft sign-in will be implemented.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onCreateAccountTap() {
    Get.toNamed(Routes.login);
  }
}
