import 'package:get/get.dart';
import '../controller/recording_summary_controller.dart';
import '../../../core/app_export.dart';

class RecordingSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordingSummaryController());
  }
}
