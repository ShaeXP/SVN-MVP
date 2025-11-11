import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:get/get.dart';
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

  // btn_continue â†’ Voice Recording Home
  void onContinuePressed() {
    // Navigate to Voice Recording Home (Home Screen) as specified
    Get.offAllNamed(Routes.root);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
