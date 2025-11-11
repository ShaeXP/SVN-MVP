import 'package:flutter/material.dart';
import 'package:get/get.dart';

PreferredSizeWidget svnAppBar({
  String? title,
  bool back = false,
  List<Widget>? actions,
  BuildContext? context,
}) {
  return AppBar(
    title: Text(title ?? 'SmartVoiceNotes'),
    leading: back
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Try nested navigator first, fallback to regular navigation
              if (Get.nestedKey(1)?.currentState?.canPop() ?? false) {
                Get.back(id: 1);
              } else if (context != null && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
          )
        : null,
    centerTitle: false,
    actions: actions,
  );
}
