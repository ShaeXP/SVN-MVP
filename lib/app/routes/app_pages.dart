import 'package:get/get.dart';
import 'package:lashae_s_application/presentation/navigation/main_navigation.dart';
import 'package:lashae_s_application/presentation/login_screen/login_screen.dart';
import 'package:lashae_s_application/presentation/login_screen/binding/login_binding.dart';
import 'package:lashae_s_application/presentation/auth/auth_gate.dart';
import 'package:lashae_s_application/presentation/auth/binding/auth_binding.dart';
import 'package:lashae_s_application/presentation/auth/confirm_email_screen.dart';
import 'package:lashae_s_application/presentation/settings_screen/settings_screen.dart';
import 'package:lashae_s_application/presentation/library/library_screen.dart';
import 'package:lashae_s_application/presentation/recording_summary_screen/recording_summary_screen.dart';
import 'package:lashae_s_application/presentation/recording_ready_screen/recording_ready_screen.dart';
import 'package:lashae_s_application/presentation/record_screen/record_screen.dart';
import 'package:lashae_s_application/presentation/recording_paused_screen/recording_paused_screen.dart';
import 'package:lashae_s_application/presentation/upload_recording_screen/upload_recording_screen.dart';
import 'package:lashae_s_application/presentation/upload_recording_screen/upload_redirect_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  // Use AuthGate to determine initial route based on auth state
  static const initial = Routes.root;

  static final pages = <GetPage<dynamic>>[
    // AuthGate determines whether to show auth or main app
    GetPage(
      name: Routes.root,
      page: () => const AuthGate(),
      participatesInRootNavigator: true,
    ),
    
    // Auth screen (outside shell)
    GetPage(
      name: Routes.authScreen,
      page: () => const AuthGate(),
      binding: AuthBinding(),
      participatesInRootNavigator: true,
    ),
    
    // Legacy login (outside shell) - kept for compatibility
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      participatesInRootNavigator: true,
    ),
    
    // Email confirmation screen
    GetPage(
      name: Routes.confirmEmail,
      page: () => const ConfirmEmailScreen(),
      binding: AuthBinding(),
      participatesInRootNavigator: true,
    ),

    // Main app shell
    GetPage(
      name: Routes.home,
      page: () => const MainNavigation(),
      participatesInRootNavigator: true,
      children: [
        // Tab routes
        GetPage(name: Routes.record, page: () => const RecordScreen()),
        GetPage(name: Routes.recordingLibrary, page: () => const LibraryScreen()),
        GetPage(name: Routes.settings, page: () => SettingsScreen()),
        
        // Detail flow routes
        GetPage(name: Routes.recordingSummary, page: () => RecordingSummaryScreen()),
        GetPage(name: Routes.recordingSummaryScreen, page: () => RecordingSummaryScreen()),
        GetPage(name: Routes.recordingReady, page: () => RecordingReadyScreen()),
        GetPage(name: Routes.activeRecording, page: () => const RecordScreen()),
        GetPage(name: Routes.recordingPaused, page: () => RecordingPausedScreen()),
        GetPage(name: Routes.uploadRecording, page: () => const UploadRecordingScreen()),
        GetPage(name: '/upload-redirect', page: () => const UploadRedirectPage()),
      ],
    ),
  ];
}