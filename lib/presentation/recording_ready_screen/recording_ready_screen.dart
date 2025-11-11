import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../library/library_screen.dart';
import '../settings_screen/settings_screen.dart';
import './controller/recording_ready_controller.dart';
import './recording_ready_screen_initial_page.dart';

// Modified: Added missing import for SettingsScreen

class RecordingReadyScreen extends GetWidget<RecordingReadyController> {
  RecordingReadyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Navigator(
        key: Get.nestedKey(1),
        initialRoute: Routes.recordingReady,
        onGenerateRoute: (routeSetting) => GetPageRoute(
          page: () => getCurrentPage(routeSetting.name!),
          transition: Transition.noTransition,
        ),
      ),
    );
  }


  Widget getCurrentPage(String currentRoute) {
    switch (currentRoute) {
      case Routes.recordingReady:
        return RecordingReadyScreenInitialPage();
      case Routes.recordingLibrary:
        return LibraryScreen();
      case Routes.settings:
        return SettingsScreen();
      default:
        return RecordingReadyScreenInitialPage();
    }
  }
}
