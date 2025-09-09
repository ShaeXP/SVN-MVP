import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../routes/app_routes.dart';

class PreviewHealthCheckController extends GetxController {
  var flutterVersion = ''.obs;
  var dartVersion = ''.obs;
  var mainExecuted = false.obs;
  var initTimestamp = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSystemInfo();
  }

  void _initializeSystemInfo() {
    try {
      // Set main() execution status - if we reached this point, main() succeeded
      mainExecuted.value = true;

      // Get current timestamp
      initTimestamp.value = DateTime.now().toString().split('.')[0];

      // Get Flutter/Dart version info
      _getVersionInfo();
    } catch (e) {
      mainExecuted.value = false;
      debugPrint('Health check initialization error: $e');
    }
  }

  void _getVersionInfo() {
    try {
      // Flutter framework version (approximate)
      flutterVersion.value = 'Flutter 3.16.x';

      // Set default Dart version since kDartVersion is not accessible
      dartVersion.value = 'Dart 3.2.x';
    } catch (e) {
      flutterVersion.value = 'Flutter ≥3.10 (Unknown)';
      dartVersion.value = 'Dart ≥3.0 (Unknown)';
      debugPrint('Version detection error: $e');
    }
  }

  void navigateToMain() {
    // Navigate to the normal app flow
    Get.offAllNamed(AppRoutes.getInitialRoute());
  }

  void navigateToLogin() {
    // Alternative navigation directly to login
    Get.offAllNamed(AppRoutes.loginScreen);
  }
}