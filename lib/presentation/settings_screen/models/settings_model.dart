import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used in the [SettingsScreen] screen with GetX.

class SettingsModel {
  Rx<String>? userName;
  Rx<String>? userEmail;
  Rx<String>? userId;
  Rx<String>? userAvatar;
  Rx<String>? appVersion;

  SettingsModel({
    this.userName,
    this.userEmail,
    this.userId,
    this.userAvatar,
    this.appVersion,
  }) {
    userName = userName ?? 'Jane Smith'.obs;
    userEmail = userEmail ?? 'demo@example.com'.obs;
    userId = userId ?? 'ID: 56d3e15c...'.obs;
    userAvatar = userAvatar ?? 'assets/images/img_rectangle_56x56.png'.obs;
    appVersion = appVersion ?? 'Version 2.1.0'.obs;
  }
}
