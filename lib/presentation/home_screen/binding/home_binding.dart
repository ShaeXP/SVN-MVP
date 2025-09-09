import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../../../core/app_export.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
