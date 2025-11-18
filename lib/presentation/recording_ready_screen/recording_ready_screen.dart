import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './controller/recording_ready_controller.dart';
import './recording_ready_screen_initial_page.dart';

class RecordingReadyScreen extends GetWidget<RecordingReadyController> {
  RecordingReadyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This screen is a child route of MainNavigation and should NOT create its own Navigator
    // It should just be a regular screen that gets pushed onto the existing nested navigator
    // Remove the Navigator wrapper to avoid duplicate GlobalKey(1) conflict
    return RecordingReadyScreenInitialPage();
  }
}
