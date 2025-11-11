import 'package:flutter/material.dart';
import 'package:get/get.dart';

void safeSnackBar({
  required String title,
  required String message,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      Get.snackbar(title, message); // will have a stable overlayContext now
    } catch (e) {
      // Fallback: no Get overlay? (e.g., nested navigator)
      final ctx = Get.context;
      if (ctx != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$title — $message')),
        );
      }
    }
  });
}

void safeNavigateBack() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  });
}
