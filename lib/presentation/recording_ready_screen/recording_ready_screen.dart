import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../recording_library_screen/recording_library_screen.dart';
import '../settings_screen/settings_screen.dart';
import './controller/recording_ready_controller.dart';
import './recording_ready_screen_initial_page.dart';

// Modified: Added missing import for SettingsScreen

class RecordingReadyScreen extends GetWidget<RecordingReadyController> {
  RecordingReadyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Navigator(
          key: Get.nestedKey(1),
          initialRoute: AppRoutes.recordingReadyScreenInitialPage,
          onGenerateRoute: (routeSetting) => GetPageRoute(
            page: () => getCurrentPage(routeSetting.name!),
            transition: Transition.noTransition,
          ),
        ),
        bottomNavigationBar: SizedBox(
          width: double.maxFinite,
          child: _buildBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Obx(() => CustomBottomBar(
          selectedIndex: controller.selectedIndex.value,
          onChanged: (index) {
            controller.selectedIndex.value = index;
            String routeName = _getRouteForIndex(index);
            Get.toNamed(routeName, id: 1);
          },
          backgroundColor: appTheme.gray_200,
        ));
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.recordingReadyScreenInitialPage;
      case 1:
        return AppRoutes.recordingLibraryScreen;
      case 2:
        return AppRoutes.settingsScreen;
      default:
        return AppRoutes.recordingReadyScreenInitialPage;
    }
  }

  Widget getCurrentPage(String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.recordingReadyScreenInitialPage:
        return RecordingReadyScreenInitialPage();
      case AppRoutes.recordingLibraryScreen:
        return RecordingLibraryScreen();
      case AppRoutes.settingsScreen:
        return SettingsScreen();
      default:
        return RecordingReadyScreenInitialPage();
    }
  }
}
