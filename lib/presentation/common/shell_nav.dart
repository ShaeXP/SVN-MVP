import 'package:get/get.dart';
import 'package:lashae_s_application/app/routes/app_routes.dart';

class ShellNav {
  static void push(String route) => Get.toNamed(route, id: 1);
  static void replaceWith(String route) => Get.offNamedUntil(route, (r) => false, id: 1);
  static void goHome() => replaceWith(Routes.home);
  static void goRecord() => replaceWith(Routes.record);
  static void goLibrary() => replaceWith(Routes.recordingLibrary);
  static void goSettings() => replaceWith(Routes.settings);
}
