import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Debug helper to instrument route checks and navigation
void debugRoutesPing(String source, String routeName) {
  final pages = Get.routeTree.routes.map((route) => route.name).toList()..sort();
  debugPrint('[ROUTES][$source] trying="$routeName" registered=${pages.contains(routeName)} all=$pages');
  debugPrint('[ROUTES][$source] currentRoute=${Get.currentRoute}, canBack=${Get.key.currentState?.canPop() == true}');
}
