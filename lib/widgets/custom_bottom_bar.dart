import 'package:flutter/material.dart';

import '../core/app_export.dart';
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
    this.selectedIndex = 0,
    required this.onChanged,
    this.backgroundColor,
    this.hasShadow,
    this.iconSize,
  }) : super(key: key);

  /// Currently selected tab index
  final int selectedIndex;

  /// Callback function triggered when a bottom bar item is tapped
  final Function(int) onChanged;

  /// Background color of the bottom bar
  final Color? backgroundColor;

  /// Whether to show shadow effect
  final bool? hasShadow;

  /// Size of the navigation icons
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? appTheme.whiteCustom,
        boxShadow: (hasShadow ?? true)
            ? [
                BoxShadow(
                  color: appTheme.color1F3817,
                  offset: Offset(0, 8.h),
                  blurRadius: 13.h,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 42.h,
          vertical: 14.h,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, "Record", ImageConstant.imgNavRecord),
            _buildNavItem(1, "Library", ImageConstant.imgNavLibrary),
            _buildNavItem(2, "Account", ImageConstant.imgNavAccount),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String iconPath) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: _getIconPath(iconPath, isSelected),
            height: iconSize ?? 20.h,
            width: iconSize ?? 20.h,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyleHelper.instance.label10OpenSans.copyWith(
                color: isSelected ? Color(0xFF88CAF5) : appTheme.gray_700,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  String _getIconPath(String basePath, bool isSelected) {
    if (!isSelected) {
      // For non-selected states, check if we need gray variant
      if (basePath.contains("record")) {
        return "assets/images/img_nav_record_gray_700.svg";
      }
      return basePath;
    }

    // For selected states, check if we need blue variant
    if (basePath.contains("library") && isSelected) {
      return "assets/images/img_nav_library_blue_200_01.svg";
    }

    return basePath;
  }
}
