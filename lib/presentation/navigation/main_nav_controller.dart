import 'package:get/get.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';

class MainNavController extends GetxController {
  final currentIndex = 0.obs;

  // Tab-to-route mapping for the nested navigator (id: 1)
  final List<String> tabRoutes = const [
    Routes.home,
    Routes.record, // Record tab points at ActiveRecording for now
    Routes.recordingLibrary,
    Routes.settings,
  ];

  void switchTab(int index) {
    if (index == currentIndex.value) {
      // Re-tapping the active tab pops to root of that tab
      final nav = Get.nestedKey(1)?.currentState;
      if (nav != null) {
        nav.popUntil((r) => r.isFirst);
      }
      return;
    }

    currentIndex.value = index;

    // Replace the nested stack with the tab's root route
    Get.offNamedUntil(
      tabRoutes[index],
      (route) => false,
      id: 1,
    );
  }
}
