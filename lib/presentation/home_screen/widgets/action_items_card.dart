import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';

class ActionItemsCard extends StatelessWidget {
  const ActionItemsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (controller.actionInbox.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (controller.actionInbox.isEmpty) 
            const Text('No action items yet.')
          else
            ...controller.actionInbox.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const Text('•  '), Expanded(child: Text(s))],
              ),
            )),
        ],
      );
    });
  }
}
