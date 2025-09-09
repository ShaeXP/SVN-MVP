import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [HomeScreen] screen with GetX.

class HomeModel {
  // Observable variables for reactive state management
  Rx<String> appTitle = "SmartVoiceNotes".obs;
  Rx<String> welcomeTitle = "Welcome to SmartVoiceNotes".obs;
  Rx<String> welcomeSubtitle =
      "Your intelligent assistant for voice-to-text notes.".obs;
  Rx<String> timerDisplay = "00:00:00".obs;
  Rx<String> emptyStateTitle = "No recordings yet".obs;
  Rx<String> emptyStateSubtitle =
      "Start capturing your ideas and memories with a single tap!".obs;

  // Simple constructor with no parameters
  HomeModel();
}
