import 'package:get/get.dart';

import '../presentation/active_recording_screen/active_recording_screen.dart';
import '../presentation/active_recording_screen/binding/active_recording_binding.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/app_navigation_screen/binding/app_navigation_binding.dart';
import '../presentation/file_upload_screen/binding/file_upload_binding.dart';
import '../presentation/file_upload_screen/file_upload_screen.dart';
import '../presentation/home_screen/binding/home_binding.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/login_screen/binding/login_binding.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/login_success_screen/binding/login_success_binding.dart';
import '../presentation/login_success_screen/login_success_screen.dart';
import '../presentation/main_navigation/binding/main_navigation_binding.dart';
import '../presentation/main_navigation/main_navigation_screen.dart';
import '../presentation/preview_health_check/binding/preview_health_check_binding.dart';
import '../presentation/preview_health_check/preview_health_check.dart';
import '../presentation/recording_control_screen/binding/recording_control_binding.dart';
import '../presentation/recording_control_screen/recording_control_screen.dart';
import '../presentation/recording_library_screen/binding/recording_library_binding.dart';
import '../presentation/recording_library_screen/recording_library_screen.dart';
import '../presentation/recording_paused_screen/binding/recording_paused_binding.dart';
import '../presentation/recording_paused_screen/recording_paused_screen.dart';
import '../presentation/recording_ready_screen/binding/recording_ready_binding.dart';
import '../presentation/recording_ready_screen/recording_ready_screen.dart';
import '../presentation/recording_ready_screen/recording_ready_screen_initial_page.dart';
import '../presentation/recording_success_screen/binding/recording_success_binding.dart';
import '../presentation/recording_success_screen/recording_success_screen.dart';
import '../presentation/recording_summary_screen/binding/recording_summary_binding.dart';
import '../presentation/recording_summary_screen/recording_summary_screen.dart';
import '../presentation/settings_screen/binding/settings_binding.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/supabase_transcription_test/binding/supabase_transcription_test_binding.dart';
import '../presentation/supabase_transcription_test/supabase_transcription_test.dart';
import '../presentation/welcome_screen/binding/welcome_binding.dart';
import '../presentation/welcome_screen/welcome_screen.dart';
import '../services/supabase_service.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String recordingPausedScreen = '/recording_paused_screen';
  static const String recordingReadyScreen = '/recording_ready_screen';
  static const String recordingReadyScreenInitialPage =
      '/recording_ready_screen_initial_page';
  static const String activeRecordingScreen = '/active_recording_screen';
  static const String recordingSummaryScreen = '/recording_summary_screen';
  static const String welcomeScreen = '/welcome_screen';
  static const String homeScreen = '/home_screen';
  static const String recordingControlScreen = '/recording_control_screen';
  static const String recordingSuccessScreen = '/recording_success_screen';
  static const String loginSuccessScreen = '/login_success_screen';
  static const String loginScreen = '/login_screen';
  static const String recordingLibraryScreen = '/recording_library_screen';
  static const String settingsScreen = '/settings_screen';
  static const String mainNavigationScreen = '/main_navigation_screen';
  static const String previewHealthCheckScreen = '/preview-health-check';
  static const String supabaseTranscriptionTestScreen =
      '/supabase-transcription-test';
  static const String fileUploadScreen = '/file_upload_screen';

  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/';

  // Auth state check function
  static String getInitialRoute() {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user != null) {
      return mainNavigationScreen; // Main navigation with bottom nav if authenticated
    }
    return loginScreen; // User Sign In if not authenticated
  }

  static List<GetPage> pages = [
    GetPage(
      name: recordingPausedScreen,
      page: () => RecordingPausedScreen(),
      bindings: [RecordingPausedBinding()],
    ),
    GetPage(
      name: recordingReadyScreen,
      page: () => RecordingReadyScreen(),
      bindings: [RecordingReadyBinding()],
    ),
    // Hidden directory screen - only accessible via Settings menu long press
    GetPage(
      name: recordingReadyScreenInitialPage,
      page: () => RecordingReadyScreenInitialPage(),
      bindings: [RecordingReadyBinding()],
    ),
    GetPage(
      name: activeRecordingScreen,
      page: () => ActiveRecordingScreen(),
      bindings: [ActiveRecordingBinding()],
    ),
    GetPage(
      name: recordingSummaryScreen,
      page: () => RecordingSummaryScreen(),
      bindings: [RecordingSummaryBinding()],
    ),
    GetPage(
      name: welcomeScreen,
      page: () => WelcomeScreen(),
      bindings: [WelcomeBinding()],
    ),
    GetPage(
      name: homeScreen,
      page: () => HomeScreen(),
      bindings: [HomeBinding()],
    ),
    GetPage(
      name: recordingControlScreen,
      page: () => RecordingControlScreen(),
      bindings: [RecordingControlBinding()],
    ),
    GetPage(
      name: recordingSuccessScreen,
      page: () => RecordingSuccessScreen(),
      bindings: [RecordingSuccessBinding()],
    ),
    GetPage(
      name: loginSuccessScreen,
      page: () => LoginSuccessScreen(),
      bindings: [LoginSuccessBinding()],
    ),
    GetPage(
      name: loginScreen,
      page: () => LoginScreen(),
      bindings: [LoginBinding()],
    ),
    GetPage(
      name: recordingLibraryScreen,
      page: () => RecordingLibraryScreen(),
      bindings: [RecordingLibraryBinding()],
    ),
    GetPage(
      name: settingsScreen,
      page: () => SettingsScreen(),
      bindings: [SettingsBinding()],
    ),
    // Main navigation screen with bottom nav
    GetPage(
      name: mainNavigationScreen,
      page: () => MainNavigationScreen(),
      bindings: [MainNavigationBinding()],
    ),
    // Preview health check screen for development/testing
    GetPage(
      name: previewHealthCheckScreen,
      page: () => PreviewHealthCheckScreen(),
      bindings: [PreviewHealthCheckBinding()],
    ),
    // Supabase transcription test screen
    GetPage(
      name: supabaseTranscriptionTestScreen,
      page: () => SupabaseTranscriptionTestScreen(),
      bindings: [SupabaseTranscriptionTestBinding()],
    ),
    GetPage(
      name: appNavigationScreen,
      page: () => AppNavigationScreen(),
      bindings: [AppNavigationBinding()],
    ),
    GetPage(
      name: initialRoute,
      page: () => LoginScreen(), // Changed to start with LoginScreen
      bindings: [LoginBinding()],
    ),
    GetPage(
      name: fileUploadScreen,
      page: () => FileUploadScreen(),
      bindings: [FileUploadBinding()],
    ),
  ];
}
