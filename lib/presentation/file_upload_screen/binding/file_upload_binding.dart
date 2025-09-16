import 'package:get/get.dart';

import '../controller/file_upload_controller.dart';

class FileUploadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FileUploadController());
  }
}
