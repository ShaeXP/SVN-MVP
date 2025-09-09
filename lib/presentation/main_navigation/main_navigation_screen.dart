import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../home_screen/home_screen.dart';
import '../recording_library_screen/recording_library_screen.dart';
import '../settings_screen/settings_screen.dart';
import './controller/main_navigation_controller.dart';

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({Key? key}) : super(key: key);

  final MainNavigationController controller =
      Get.put(MainNavigationController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Obx(() => _getCurrentScreen()),
        bottomNavigationBar: Obx(() => CustomBottomBar(
              selectedIndex: controller.selectedIndex.value,
              onChanged: (index) => controller.onNavItemTapped(index),
              backgroundColor: appTheme.whiteCustom,
              hasShadow: true,
              iconSize: 20.h,
            )),
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (controller.selectedIndex.value) {
      case 0:
        return HomeScreen(); // Voice Recording Home
      case 1:
        return RecordingLibraryScreen(); // Recording Library
      case 2:
        return SettingsScreen(); // Settings Menu
      default:
        return HomeScreen();
    }
  }
}
