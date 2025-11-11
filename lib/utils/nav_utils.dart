import 'package:get/get.dart';
import '../app/navigation/bottom_nav_controller.dart';
import '../app/routes/app_routes.dart';

class NavUtils {
  static const int kHomeTabIndex = 0; // Home tab is index 0
  static const String kMainShellRoute = Routes.root; // Routes.root is '/' which points to MainNavigation

  /// Navigate to the true Home inside the main shell
  /// This switches to the Home tab and resets the navigation stack
  static void goHome() {
    // Switch the bottom tab to Home if controller exists
    if (Get.isRegistered<BottomNavController>()) {
      final nav = Get.find<BottomNavController>();
      nav.goTab(kHomeTabIndex);
    }

    // Reset the root stack to the main shell (avoid pushing a second Home)
    if (Get.currentRoute != kMainShellRoute) {
      Get.offAllNamed(kMainShellRoute);
    } else {
      // already at root shell; also pop inner nested navigators to their first routes if used
      if (Get.key.currentState != null) {
        Get.key.currentState!.popUntil((r) => r.isFirst);
      }
    }
  }
}
