import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ui/visuals/brand_background.dart';
import '../../ui/visuals/glass_dock.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../home_screen/home_screen.dart';
import '../library/library_screen.dart';
import '../settings_screen/settings_screen.dart';
import '../record_screen/record_screen.dart';
import './controller/main_navigation_controller.dart';

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({Key? key}) : super(key: key);

  final MainNavigationController controller =
      Get.find<MainNavigationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // DEBUG
      body: Stack(
        children: [
          const ColoredBox(color: Colors.blue), // DEBUG
          SafeArea(
            child: Obx(() => IndexedStack(
              index: controller.selectedIndex.value,
              children: const [
                HomeScreen(),
                RecordScreen(),
                SettingsScreen(),
              ],
            )),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => GlassDock(
        child: CustomBottomBar(
          selectedIndex: controller.selectedIndex.value,
          onChanged: (index) => controller.onNavItemTapped(index),
          backgroundColor: Colors.transparent,
          hasShadow: false,
          iconSize: 24.0,
        ),
      )),
    );
  }

}