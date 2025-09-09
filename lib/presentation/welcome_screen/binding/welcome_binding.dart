import 'package:get/get.dart';
import '../controller/welcome_controller.dart';
import '../../../core/app_export.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WelcomeController());
  }
}
