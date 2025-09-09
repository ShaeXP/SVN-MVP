import 'package:get/get.dart';
import '../controller/recording_library_controller.dart';
import '../../../core/app_export.dart';

class RecordingLibraryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingLibraryController());
  }
}
