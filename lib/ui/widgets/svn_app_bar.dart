import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_text_styles.dart';

class SVNAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showActions;
  final VoidCallback? onEditPressed;
  final bool isEditing;
  const SVNAppBar({
    super.key, 
    this.showActions = true,
    this.onEditPressed,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      // Home is a root tab; never show an automatic back button here.
      // Detail screens use their own AppBars for back navigation.
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 56, // compact, kills wasted space
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleSpacing: 16,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08), // Subtle blur for readability
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo from assets
          Image.asset(
            'assets/images/img_img_logomic.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text('SmartVoiceNotes', style: AppTextStyles.appTitle(context).copyWith(color: Colors.white)),
        ],
      ),
      actions: showActions
          ? [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check : Icons.more_vert, 
                  color: Colors.white
                ),
                onPressed: onEditPressed,
                tooltip: isEditing ? 'Done' : 'Edit',
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// Reactive version of SVNAppBar that can be used with Obx
class ReactiveSVNAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showActions;
  final RxBool isEditing;
  final VoidCallback? onEditPressed;
  
  const ReactiveSVNAppBar({
    super.key, 
    this.showActions = true,
    required this.isEditing,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => SVNAppBar(
      showActions: showActions,
      isEditing: isEditing.value,
      onEditPressed: onEditPressed,
    ));
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
