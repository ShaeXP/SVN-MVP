import 'package:get/get.dart';
import '../controller/active_recording_controller.dart';
import '../../../core/app_export.dart';

class ActiveRecordingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ActiveRecordingController());
  }
}
