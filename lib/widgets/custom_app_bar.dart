import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomAppBar - A customizable app bar component with leading, trailing, and center logo images
 */
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final double? height;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  
  // Legacy support
  final String? leadingImagePath;
  final String? trailingImagePath;
  final String? centerLogoImagePath;

  const CustomAppBar({
    Key? key,
    this.leading,
    this.center,
    this.trailing,
    this.height,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.leadingImagePath, // Legacy support
    this.trailingImagePath, // Legacy support
    this.centerLogoImagePath, // Legacy support
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height ?? 108.0);

  @override
  Widget build(BuildContext context) {
    // Use leadingImagePath if provided (legacy), otherwise use leading
    Widget? displayLeading = leading;
    if (leadingImagePath != null && leading == null) {
      displayLeading = CustomImageView(
        imagePath: leadingImagePath!,
        height: 10.0,
        width: 26.0,
      );
    }

    // Use trailingImagePath if provided (legacy), otherwise use trailing
    Widget? displayTrailing = trailing;
    if (trailingImagePath != null && trailing == null) {
      displayTrailing = CustomImageView(
        imagePath: trailingImagePath!,
        height: 10.0,
        width: 26.0,
      );
    }

    // Use centerLogoImagePath if provided (legacy), otherwise use center
    Widget? displayCenter = center;
    if (centerLogoImagePath != null && center == null) {
      displayCenter = CustomImageView(
        imagePath: centerLogoImagePath!,
        height: 10.0,
        width: 64.0,
      );
    }

    return AppBar(
      backgroundColor: backgroundColor ?? appTheme.white_A700,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: height ?? 108.0,
      flexibleSpace: Container(
        padding: EdgeInsets.only(
          top: 12.0,
          right: 18.0,
          bottom: 12.0,
          left: 18.0,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Leading widget
              if (displayLeading != null) ...[
                displayLeading!,
                SizedBox(width: 26.0),
              ] else if (automaticallyImplyLeading) ...[
                Container(
                  margin: EdgeInsets.only(top: 4.0, left: 10.0),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgGroup,
                    height: 10.0,
                    width: 26.0,
                  ),
                ),
                SizedBox(width: 26.0),
              ],
              
              // Center widget
              if (displayCenter != null) ...[
                Expanded(child: Center(child: displayCenter!)),
              ] else ...[
                Expanded(
                  child: Center(
                    child: CustomImageView(
                      imagePath: ImageConstant.imgImageGray900,
                      height: 10.0,
                      width: 64.0,
                    ),
                  ),
                ),
                SizedBox(width: 64.0),
              ],
              
              // Trailing widget
              if (displayTrailing != null) displayTrailing!,
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(14.0),
        child: Container(
          height: 54.0,
          width: 68.0,
          decoration: BoxDecoration(
            color: appTheme.color7FDEE1,
            borderRadius: BorderRadius.circular(27.0),
          ),
        ),
      ),
    );
  }
}
