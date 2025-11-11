import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:get/get.dart';
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

  // btn_register â†’ Voice Recording Home
  void onGetStartedPressed() {
    // Navigate to Voice Recording Home (Home Screen) as specified
    Get.toNamed(Routes.root);
  }

  // btn_loginRedirect â†’ User Sign In
  void onSignInPressed() {
    // Navigate to User Sign In (Login Screen) as specified
    Get.toNamed(Routes.login);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
