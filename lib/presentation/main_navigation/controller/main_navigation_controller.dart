import '../../../core/app_export.dart';

class MainNavigationController extends GetxController {
  var selectedIndex = 0.obs;

  /// Handle navigation item tap
  void onNavItemTapped(int index) {
    selectedIndex.value = index;
  }

  /// Set selected index programmatically
  void setSelectedIndex(int index) {
    if (index >= 0 && index <= 2) {
      selectedIndex.value = index;
    }
  }

  /// Navigate to specific screen and update bottom nav
  void navigateToScreen(int screenIndex) {
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
