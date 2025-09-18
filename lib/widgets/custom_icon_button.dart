import 'package:sizer/sizer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_export.dart';
import '../core/utils/size_utils.dart';
import './custom_image_view.dart';

/**
 * A customizable icon button widget with background styling and SVG icon support.
 * 
 * This widget provides a reusable icon button component with configurable background color,
 * icon path, and size. It uses CustomImageView for image handling and supports
 * responsive design through SizeUtils extensions.
 * 
 * @param iconPath - Path to the SVG icon asset (required)
 * @param onPressed - Callback function when button is pressed
 * @param backgroundColor - Background color of the button
 * @param size - Size of the button (width and height)
 * @param iconSize - Size of the icon within the button
 */
class CustomIconButton extends StatelessWidget {
  CustomIconButton({
    Key? key,
    required this.iconPath,
    this.onPressed,
    this.backgroundColor,
    this.size,
    this.iconSize,
  }) : super(key: key);

  /// Path to the SVG icon asset
  final String iconPath;

  /// Callback function triggered when button is pressed
  final VoidCallback? onPressed;

  /// Background color of the button
  final Color? backgroundColor;

  /// Size of the button (width and height)
  final double? size;

  /// Size of the icon within the button
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final buttonSize = size?.h ?? 40.h;
    final iconDimension = iconSize?.h ?? 24.h;
    final bgColor = backgroundColor ?? Color(0xFF1988CA);

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.h),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: CustomImageView(
          imagePath: iconPath,
          height: iconDimension,
          width: iconDimension,
          fit: BoxFit.contain,
        ),
        padding: EdgeInsets.all(8.h),
        splashRadius: (buttonSize / 2) - 2.h,
      ),
    );
  }
}
