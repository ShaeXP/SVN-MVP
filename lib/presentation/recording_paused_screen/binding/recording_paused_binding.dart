import 'package:get/get.dart';
import '../controller/recording_paused_controller.dart';
import '../../../core/app_export.dart';

class RecordingPausedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingPausedController());
  }
}
