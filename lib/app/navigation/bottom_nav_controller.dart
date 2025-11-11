import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  static BottomNavController get I {
    if (!Get.isRegistered<BottomNavController>()) {
      return Get.put(BottomNavController(), permanent: true);
    }
    return Get.find<BottomNavController>();
  }

  static const routeHome = '/home';
  static const routeRecord = '/active-recording';
  static const routeLibrary = '/recording-library';
  static const routeSettings = '/settings';

  // include child prefixes so highlight stays right
  static const _homeRoutes = [routeHome, '/'];
  static const _recordRoutes = [routeRecord, '/upload-recording', '/record', '/recorder', '/recording-ready', '/recording-paused'];
  static const _libraryRoutes = [routeLibrary, '/recording-summary', '/recording-detail', '/summary', '/library'];
  static const _settingsRoutes = [routeSettings, '/prefs'];

  final index = 0.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[DI] BottomNavController onInit');
  }

  int indexForRoute(String? name) {
    final r = name ?? '';
    bool any(List<String> ps) => ps.any((p) => r.startsWith(p));
    if (any(_settingsRoutes)) return 3;
    if (any(_libraryRoutes)) return 2;
    if (any(_recordRoutes)) return 1;
    return 0;
  }

  String routeFor(int i) {
    switch (i) {
      case 1: return routeRecord;
      case 2: return routeLibrary;
      case 3: return routeSettings;
      default: return routeHome;
    }
  }

  void onRouteChanged(String? name) => index.value = indexForRoute(name);

  /// Switch tabs using IndexedStack - no route pushing
  Future<void> goTab(int i) async {
    // Close any sheet/dialog first
    while ((Get.isBottomSheetOpen ?? false) || (Get.isDialogOpen ?? false)) {
      Get.back<dynamic>();
    }

    // Just set the index - IndexedStack will handle the rest
    index.value = i;
  }

  // Convenience
  Future<void> goHome() => goTab(0);
  Future<void> goRecord() => goTab(1);
  Future<void> goLibrary() => goTab(2);
  Future<void> goSettings() => goTab(3);

  /// For pushing child pages under a tab while keeping highlight correct
  Future<void> pushChildOf({required int tabIndex, required String route, dynamic arguments}) async {
    index.value = tabIndex;
    await Get.toNamed(route, arguments: arguments);
  }
}
