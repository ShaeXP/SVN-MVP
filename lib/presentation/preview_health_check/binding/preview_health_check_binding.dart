import 'package:get/get.dart';
import '../controller/preview_health_check_controller.dart';

class PreviewHealthCheckBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PreviewHealthCheckController());
  }
}
