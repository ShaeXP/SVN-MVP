import 'package:get/get.dart';
import '../controller/recording_success_controller.dart';
import '../../../core/app_export.dart';

class RecordingSuccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingSuccessController());
  }
}
