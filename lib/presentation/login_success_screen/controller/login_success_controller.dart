import '../../../core/app_export.dart';

class LoginSuccessController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  // btn_continue → Voice Recording Home
  void onContinuePressed() {
    // Navigate to Voice Recording Home (Home Screen) as specified
    Get.offAllNamed(AppRoutes.homeScreen);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
