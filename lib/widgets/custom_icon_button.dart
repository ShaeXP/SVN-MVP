import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../core/utils/size_utils.dart';
import './custom_image_view.dart';

/**
 * A custom icon button widget that provides consistent styling and behavior
 * across the application.
 */
class CustomIconButton extends StatelessWidget {
  /// The icon to display in the button
  final Widget? icon;

  /// The size of the button (width and height)
  final double? size;

  /// The size of the icon within the button
  final double? iconSize;

  /// The background color of the button
  final Color? backgroundColor;

  /// The border radius of the button
  final double? borderRadius;

  /// The padding around the icon
  final EdgeInsets? padding;

  /// The margin around the button
  final EdgeInsets? margin;

  /// Callback function when the button is pressed
  final VoidCallback? onTap;

  /// Whether the button is enabled
  final bool enabled;

  /// The splash radius for the ripple effect
  final double? splashRadius;

  // Legacy support for old parameter names
  final String? iconPath;

  const CustomIconButton({
    Key? key,
    this.icon,
    this.size,
    this.iconSize,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.enabled = true,
    this.splashRadius,
    // Legacy support
    this.iconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonSize = size?.h ?? 40.h;
    final iconDimension = iconSize?.h ?? 24.h;

    // Use iconPath if provided (legacy support), otherwise use icon
    Widget? displayIcon = icon;
    if (iconPath != null && icon == null) {
      displayIcon = CustomImageView(
        imagePath: iconPath!,
        height: iconDimension,
        width: iconDimension,
      );
    }

    return Container(
      margin: margin,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius?.h ?? 10.h),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(borderRadius?.h ?? 10.h),
          splashColor: enabled ? Colors.grey.withOpacity(0.2) : Colors.transparent,
          highlightColor: enabled ? Colors.grey.withOpacity(0.1) : Colors.transparent,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            padding: padding ?? EdgeInsets.all(8.h),
            child: Center(
              child: SizedBox(
                width: iconDimension,
                height: iconDimension,
                child: displayIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
