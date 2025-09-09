import 'package:get/get.dart';
import '../controller/login_controller.dart'; // Modified: Fixed import path
import '../../../core/app_export.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
