import 'package:get/get.dart';
import '../controller/recording_control_controller.dart';
import '../../../core/app_export.dart';

class RecordingControlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingControlController());
  }
}
