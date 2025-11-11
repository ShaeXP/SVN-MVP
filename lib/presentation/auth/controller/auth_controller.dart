import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lashae_s_application/presentation/navigation/main_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final error = ''.obs;

  final signInFormKey = GlobalKey<FormState>();
  final signUpFormKey = GlobalKey<FormState>();

  String? validateEmail(String? v) { 
    if (v == null || v.trim().isEmpty) return 'Email required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> signIn() async {
    if (!(signInFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true; 
    error.value = '';
    try {
      await supabase.auth.signInWithPassword(
        email: email.value.trim(),
        password: password.value,
      );
      Get.offAll(() => const MainNavigation());
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        error.value = 'You need to confirm your email before signing in. We can resend the email.';
        // Show resend option
        Get.snackbar(
          'Email Confirmation Required',
          'Check your email and click the confirmation link, or we can resend it.',
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => resendConfirmation(email.value.trim()),
            child: const Text('Resend'),
          ),
        );
      } else {
        error.value = e.message == 'Invalid login credentials'
          ? 'Incorrect email or password'
          : e.message;
      }
    } catch (e) {
      error.value = 'Unexpected error. Try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp() async {
    if (!(signUpFormKey.currentState?.validate() ?? false)) return;
    isLoading.value = true; 
    error.value = '';
    try {
      final response = await supabase.auth.signUp(
        email: email.value.trim(),
        password: password.value,
        emailRedirectTo: 'https://updates.smartvoicenotes.com/confirmed',
      );
      
      if (response.user != null) {
        // Navigate to email confirmation screen
        Get.toNamed('/confirm-email', arguments: {'email': email.value.trim()});
      }
    } on AuthException catch (e) {
      error.value = e.message.contains('already registered')
        ? 'An account with this email already exists'
        : e.message;
    } catch (e) {
      error.value = 'Unexpected error. Try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendConfirmation(String email) async {
    isLoading.value = true;
    error.value = '';
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'https://updates.smartvoicenotes.com/confirmed',
      );
      Get.snackbar('Success', 'Confirmation email sent');
    } on AuthException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = 'Failed to resend email. Try again.';
    } finally {
      isLoading.value = false;
    }
  }
}