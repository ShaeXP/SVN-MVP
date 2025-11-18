import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for managing onboarding state and persistence
class OnboardingService extends GetxService {
  static const String _keyHomeOnboardingDismissed = 'home_onboarding_dismissed';

  final _homeOnboardingDismissed = false.obs;
  bool get isHomeOnboardingDismissed => _homeOnboardingDismissed.value;

  Future<OnboardingService> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _homeOnboardingDismissed.value =
          prefs.getBool(_keyHomeOnboardingDismissed) ?? false;
      debugPrint('[OnboardingService] Initialized: home_onboarding_dismissed=${_homeOnboardingDismissed.value}');
    } catch (e) {
      debugPrint('[OnboardingService] Error loading preferences: $e');
      // Default to false (show onboarding) on error
      _homeOnboardingDismissed.value = false;
    }
    return this;
  }

  Future<void> dismissHomeOnboarding() async {
    try {
      _homeOnboardingDismissed.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHomeOnboardingDismissed, true);
      debugPrint('[OnboardingService] Home onboarding dismissed');
    } catch (e) {
      debugPrint('[OnboardingService] Error saving dismissal: $e');
    }
  }
}

