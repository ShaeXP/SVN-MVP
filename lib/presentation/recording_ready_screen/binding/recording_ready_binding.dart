import 'package:get/get.dart';
import '../controller/recording_ready_controller.dart';
import '../../../core/app_export.dart';

class RecordingReadyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingReadyController());
  }
}
