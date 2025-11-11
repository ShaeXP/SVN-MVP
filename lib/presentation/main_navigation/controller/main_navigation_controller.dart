import 'package:get/get.dart';
import '../../../core/app_export.dart';
import '../../../services/logger.dart';

class MainNavigationController extends GetxController {
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    logx('Main navigation initialized', tag: 'NAV');
  }

  /// Handle navigation item tap
  void onNavItemTapped(int index) {
    logx('Navigation item tapped: $index', tag: 'NAV');
    selectedIndex.value = index;
  }

  /// Set selected index programmatically
  void setSelectedIndex(int index) {
    if (index >= 0 && index <= 2) {
      logx('Navigation index set to: $index', tag: 'NAV');
      selectedIndex.value = index;
    }
  }

  /// Navigate to specific screen and update bottom nav
  void navigateToScreen(int screenIndex) {
    logx('Navigate to screen: $screenIndex', tag: 'NAV');
    selectedIndex.value = screenIndex;
  }

  /// Get current screen name for debugging
  String getCurrentScreenName() {
    switch (selectedIndex.value) {
      case 0:
        return 'Voice Recording Home';
      case 1:
        return 'Recording Library';
      case 2:
        return 'Settings Menu';
      default:
        return 'Unknown';
    }
  }
}
