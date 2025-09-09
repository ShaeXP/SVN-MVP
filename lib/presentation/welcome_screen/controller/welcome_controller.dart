import '../../../core/app_export.dart';

class WelcomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  // btn_register → Voice Recording Home
  void onGetStartedPressed() {
    // Navigate to Voice Recording Home (Home Screen) as specified
    Get.toNamed(AppRoutes.homeScreen);
  }

  // btn_loginRedirect → User Sign In
  void onSignInPressed() {
    // Navigate to User Sign In (Login Screen) as specified
    Get.toNamed(AppRoutes.loginScreen);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
