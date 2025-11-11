import 'package:get/get.dart';
import '../recording_controller.dart';
import '../../../core/app_export.dart';

class ActiveRecordingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingController());
  }
}
