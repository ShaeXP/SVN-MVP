import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/core/utils/image_constant.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';
import './custom_image_view.dart';

/**
 * CustomBottomBar is a navigation component that displays three fixed navigation items:
 * Record, Library, and Account. It supports active/inactive states with different
 * visual styles and handles navigation through callback functions.
 * 
 * @param selectedIndex - Currently selected tab index (0, 1, or 2)
 * @param onChanged - Callback function that receives the tapped item index
 * @param backgroundColor - Background color of the bottom bar
 * @param hasShadow - Whether to show shadow effect above the bottom bar
 * @param iconSize - Size of the navigation icons (20 or 24)
 */
class CustomBottomBar extends StatelessWidget {
  CustomBottomBar({
    Key? key,
    required this.selectedIndex,
    required this.onChanged,
    this.backgroundColor,
    this.hasShadow = false,
    this.iconSize,
  }) : super(key: key);

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? backgroundColor;
  final bool hasShadow;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavActiveColor = const Color(0xFF6E56CF); // brand purple already used
    final bottomNavInactiveColor = const Color(0xCC4B5563); // slightly darker for better contrast
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.12); // subtle top hairline

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border(
          top: BorderSide(width: 1.0, color: borderColor),
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: appTheme.color281E12.withOpacity(0.1),
                  offset: const Offset(0, 8.0),
                  blurRadius: 13.0,
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 42.w,
            vertical: 14.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: ImageConstant.imgNavRecord,
                activeIcon: ImageConstant.imgNavRecord,
                label: 'Record',
              ),
              _buildNavItem(
                index: 1,
                icon: ImageConstant.imgNavLibrary,
                activeIcon: ImageConstant.imgNavLibraryBlue20001,
                label: 'Library',
              ),
              _buildNavItem(
                index: 2,
                icon: ImageConstant.imgNavAccount,
                activeIcon: ImageConstant.imgNavAccount,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    // Brand-consistent colors scoped locally for this builder
    const activeColor = Color(0xFF6E56CF);     // brand purple
    const inactiveColor = Color(0xCC4B5563);  // slightly darker inactive
    
    return GestureDetector(
      onTap: () => onChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: iconSize ?? 24.0,
            width: iconSize ?? 24.0,
            child: CustomImageView(
              imagePath: isSelected ? activeIcon : icon,
              height: iconSize ?? 24.0,
              width: iconSize ?? 24.0,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: isSelected
                ? TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                    color: activeColor,   // brand violet
                    fontWeight: FontWeight.w600,
                  )
                : TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                    color: inactiveColor, // slightly darker inactive
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }
}
