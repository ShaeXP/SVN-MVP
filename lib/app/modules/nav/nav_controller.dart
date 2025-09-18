import 'package:get/get.dart';

class NavController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final tabs = const [
    'homeStack',
    'recordStack',
    'libraryStack',
    'settingsStack'
  ];

  void switchTab(int i) => currentIndex.value = i;

  Future<bool> onWillPop() async {
    final i = currentIndex.value;
    final canPop = Get.nestedKey(tabs[i])?.currentState?.canPop() ?? false;
    if (canPop) {
      Get.nestedKey(tabs[i])?.currentState?.pop();
      return false;
    }
    if (i != 0) {
      currentIndex.value = 0;
      return false;
    }
    return true;
  }
}
