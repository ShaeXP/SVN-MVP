import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // LOGIN-FIRST: Added for direct Supabase auth
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/supabase_service.dart';
import '../models/setting_item_model.dart';
import '../models/settings_model.dart';
import '../../home_screen/controller/home_controller.dart';

class SettingsController extends GetxController {
  Rx<SettingsModel> settingsModelObj = SettingsModel().obs;
  RxList<SettingItemModel> additionalSettings = <SettingItemModel>[].obs;

  // Long press timer for hidden screen access
  Timer? _longPressTimer;
  final RxInt _longPressDuration = 0.obs;

  // Persistent app preferences
  final normalizeAudio = false.obs;        // Audio pre-process switch
  final summarizeStyle = 'concise_actions'.obs; // enum-like key

  // NEW – Audio & AI
  final autoTrimSilence = true.obs;          // UI toggle; backend handles trimming
  final languageHint = 'auto'.obs;           // 'auto', 'en', 'es', etc.
  final autoSendEmail = false.obs;           // after summary

  // NEW – Privacy
  final analyticsOptIn = false.obs;
  final crashOptIn = false.obs;
  final redactPII = true.obs;                // signal backend to redact emails/phones/addresses
  final dataRetentionDays = 30.obs;
  final publishRedactedSamples = false.obs;   // publish de-identified samples (public)          // 7, 30, 90, 0 (0 = keep forever)

  // NEW – Account (read-only + actions)
  final accountEmail = ''.obs;
  final accountPlan = 'Free (MVP)'.obs;

  // Metrics state
  final metricsLoading = false.obs;
  final metricsError = RxnString();
  final metrics = Rxn<Map<String, dynamic>>();

  // Preferences keys
  static const _kNormalize = 'normalize_audio';
  static const _kStyle = 'summarize_style';
  static const _kTrim = 'auto_trim';
  static const _kLang = 'language_hint';
  static const _kAutoEmail = 'auto_email';
  static const _kAnalytics = 'analytics_opt_in';
  static const _kCrash = 'crash_opt_in';
  static const _kPII = 'redact_pii';
  static const _kRetention = 'retention_days';
  static const _kPublishSamples = 'publish_redacted_samples';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DI] SettingsController onInit');
    _initializeAdditionalSettings();
    _loadUserProfile();
    _loadPrefs();
    _loadAccount();
    refreshMetrics(); // kick off metrics once
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _longPressTimer?.cancel();
    super.onClose();
  }

  void _initializeAdditionalSettings() {
    additionalSettings.value = [
      SettingItemModel(
        iconPath: ImageConstant.imgContainer.obs,
        backgroundColor: '#19a855f7'.obs,
        title: 'Audio Settings'.obs,
        subtitle: 'Quality: Low Quality • Sensitivity: Normal'.obs,
      ),
      SettingItemModel(
        iconPath: ImageConstant.imgContainerBlueA700.obs,
        backgroundColor: '#193b82f6'.obs,
        title: 'Teams'.obs,
        subtitle: 'Manage team members and permissions'.obs,
      ),
      SettingItemModel(
        iconPath: ImageConstant.imgIconBilling.obs,
        backgroundColor: '#196366f1'.obs,
        title: 'Billing & Usage'.obs,
        subtitle: 'Manage your subscription and usage'.obs,
      ),
    ];
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await SupabaseService.instance.getUserProfile();
      if (profile != null) {
        settingsModelObj.value.userName?.value =
            profile['full_name'] ?? 'Unknown User';
        settingsModelObj.value.userEmail?.value =
            profile['email'] ?? 'No email';
        settingsModelObj.value.userId?.value =
            'ID: ${profile['id'].toString().substring(0, 8)}...';
      }
    } catch (error) {
      // Non-blocking: log but don't show snackbar on Settings init
      if (kDebugMode) {
        print('[Settings] Failed to load user profile: $error');
      }
      // Set fallback values
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        settingsModelObj.value.userEmail?.value = user.email ?? 'No email';
        settingsModelObj.value.userId?.value = 'ID: ${user.id.substring(0, 8)}...';
      }
    }
  }

  // 2-second long press handler for accessing hidden screen
  void onAppLogoLongPress() {
    _longPressDuration.value = 0;

    // Show progress indicator
    Get.dialog(
      Dialog(
        child: Container(
          padding: EdgeInsets.all(20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hold for 2 seconds to access hidden screen',
                style: TextStyleHelper.instance.body14RegularOpenSans,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Obx(() => LinearProgressIndicator(
                    value: _longPressDuration.value / 20.0,
                    backgroundColor: appTheme.gray_300,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(appTheme.blue_200_01),
                  )),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  _longPressTimer?.cancel();
                  Get.back();
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Start timer for 2 seconds
    _longPressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _longPressDuration.value += 1;

      if (_longPressDuration.value >= 20) {
        timer.cancel();
        Get.back(); // Close progress dialog

        // Navigate to hidden screen
        Get.toNamed(Routes.recordingReady, id: 1);

        Get.snackbar(
          'Hidden Screen Access',
          'Welcome to the developer screen!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.teal_600,
          colorText: appTheme.white_A700,
        );
      }
    });
  }

  void onAppearanceTap() {
    Get.snackbar(
      'Appearance',
      'Theme settings will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onAIPreferencesTap() {
    Get.snackbar(
      'AI Preferences',
      'AI settings will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onNotificationsTap() {
    Get.snackbar(
      'Notifications',
      'Notification settings will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onEditProfileTap() {
    Get.snackbar(
      'Edit Profile',
      'Profile editing will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onSignOutPressed() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      // LOGIN-FIRST: Navigate back to standalone login, history cleared
      Get.offAllNamed(Routes.login);
    }
  }

  void onAdditionalSettingTap(int index) {
    final setting = additionalSettings[index];
    Get.snackbar(
      setting.title?.value ?? '',
      'This setting will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onExportPreferencesTap() {
    Get.snackbar(
      'Export Preferences',
      'Export settings will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onPrivacySecurityTap() {
    Get.snackbar(
      'Privacy & Security',
      'Privacy settings will open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onResetToDefaultsTap() {
    Get.dialog(
      AlertDialog(
        title: Text('Reset Settings'),
        content: Text(
            'Are you sure you want to reset all settings to their default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _resetAllSettings();
              Get.snackbar(
                'Settings Reset',
                'All settings have been restored to default values',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: appTheme.teal_600,
                colorText: appTheme.white_A700,
              );
            },
            child: Text('Reset',
                style: TextStyleHelper.instance.body14RegularOpenSans
                    .copyWith(color: appTheme.red_400)),
          ),
        ],
      ),
    );
  }

  void _resetAllSettings() {
    settingsModelObj.value = SettingsModel();
    _initializeAdditionalSettings();
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    normalizeAudio.value = p.getBool(_kNormalize) ?? false;
    summarizeStyle.value = p.getString(_kStyle) ?? 'concise_actions';
    autoTrimSilence.value = p.getBool(_kTrim) ?? true;
    languageHint.value = p.getString(_kLang) ?? 'auto';
    autoSendEmail.value = p.getBool(_kAutoEmail) ?? false;

    analyticsOptIn.value = p.getBool(_kAnalytics) ?? false;
    crashOptIn.value = p.getBool(_kCrash) ?? false;
    redactPII.value = p.getBool(_kPII) ?? true;
    dataRetentionDays.value = p.getInt(_kRetention) ?? 30;
    publishRedactedSamples.value = p.getBool(_kPublishSamples) ?? false;
  }

  /// Load account information
  Future<void> _loadAccount() async {
    final user = Supabase.instance.client.auth.currentUser;
    accountEmail.value = user?.email ?? '';
    try {
      // profiles(plan) -> adjust table/column names to your schema
      final row = await Supabase.instance.client.from('profiles').select('plan').single();
      if (row['plan'] != null) accountPlan.value = row['plan'].toString();
    } catch (_) {/* keep default */}
  }

  /// Set normalize audio preference
  Future<void> setNormalizeAudio(bool v) async {
    normalizeAudio.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNormalize, v);
  }

  /// Set summarization style preference
  Future<void> setSummarizeStyle(String v) async {
    summarizeStyle.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStyle, v);
  }

  /// Set auto trim preference
  Future<void> setAutoTrim(bool v) async {
    autoTrimSilence.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kTrim, v);
  }

  /// Set language hint preference
  Future<void> setLanguageHint(String v) async {
    languageHint.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, v);
  }

  /// Set auto send email preference
  Future<void> setAutoSendEmail(bool v) async {
    autoSendEmail.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoEmail, v);
  }

  /// Set analytics opt-in preference
  Future<void> setAnalytics(bool v) async {
    analyticsOptIn.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAnalytics, v);
  }

  /// Set crash opt-in preference
  Future<void> setCrash(bool v) async {
    crashOptIn.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kCrash, v);
  }

  /// Set redact PII preference
  Future<void> setRedact(bool v) async {
    redactPII.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPII, v);
  }

  /// Set data retention preference
  Future<void> setRetention(int days) async {
    dataRetentionDays.value = days;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kRetention, days);
  }

  /// Set publish redacted samples preference
  Future<void> setPublishSamples(bool v) async {
    publishRedactedSamples.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPublishSamples, v);
  }

  /// Refresh pipeline metrics
  Future<void> refreshMetrics() async {
    try {
      metricsLoading.value = true;
      metricsError.value = null;
      // Call your existing supabase function or RPC, e.g. 'sv_metrics_7d'
      final resp = await Supabase.instance.client.functions.invoke('sv_metrics_7d', body: {});
      if (resp.status != 200) {
        final errorMsg = resp.data is Map ? (resp.data['message']?.toString() ?? '') : resp.data?.toString() ?? '';
        throw Exception('Function error (${resp.status}): ${errorMsg.isEmpty ? "No error message" : errorMsg}');
      }
      final data = (resp.data as Map).cast<String, dynamic>();
      metrics.value = data;
    } catch (e) {
      metricsError.value = e.toString();
    } finally {
      metricsLoading.value = false;
    }
  }

  /// Reset all settings to defaults including Home layout preferences
  Future<void> resetToDefaults() async {
    try {
      // Clear Home layout preferences
      final prefs = await SharedPreferences.getInstance();
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
      final homeLayoutKey = 'home_layout_$uid';
      await prefs.remove(homeLayoutKey);
      
      // Clear app preferences
      await prefs.remove(_kNormalize);
      await prefs.remove(_kStyle);
      await prefs.remove(_kTrim);
      await prefs.remove(_kLang);
      await prefs.remove(_kAutoEmail);
      await prefs.remove(_kAnalytics);
      await prefs.remove(_kCrash);
      await prefs.remove(_kPII);
      await prefs.remove(_kRetention);
      await prefs.remove(_kPublishSamples);
      
      // Reset current settings model
      _resetAllSettings();
      
      // Reload preferences to defaults
      await _loadPrefs();
      
      // Refresh HomeController if it exists
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.loadLayout();
      }
      
      debugPrint('[Settings] Reset to defaults completed');
    } catch (e) {
      debugPrint('[Settings] Failed to reset to defaults: $e');
      rethrow;
    }
  }
}
