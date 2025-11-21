import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/navigation/bottom_nav_controller.dart';

class UploadRedirectPage extends StatefulWidget {
  const UploadRedirectPage({super.key});
  @override
  State<UploadRedirectPage> createState() => _UploadRedirectPageState();
}

class _UploadRedirectPageState extends State<UploadRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navigatorContext = context;
      await Get.toNamed(
        BottomNavController.routeRecord,
        arguments: {'autoUpload': true},
        id: 1,
      );
      if (mounted && navigatorContext.mounted && Navigator.canPop(navigatorContext)) {
        Navigator.pop(navigatorContext); // remove the redirect page from stack
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

