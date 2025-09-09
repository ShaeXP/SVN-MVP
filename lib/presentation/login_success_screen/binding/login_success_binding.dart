import 'package:get/get.dart';
import '../controller/login_success_controller.dart';
import '../../../core/app_export.dart';

class LoginSuccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginSuccessController());
  }
}
