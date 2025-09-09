import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomAppBar - A customizable app bar component with leading, trailing, and center logo images
 * 
 * This component provides a flexible app bar implementation that supports:
 * - Leading image (typically navigation or menu icon)
 * - Trailing image (typically profile or settings icon) 
 * - Center logo image positioned below the top row
 * - Customizable background color and height
 * - Responsive design with proper spacing and alignment
 * 
 * @param leadingImagePath - Path to the leading image (SVG/PNG)
 * @param trailingImagePath - Path to the trailing image (SVG/PNG)
 * @param centerLogoImagePath - Path to the center logo image (SVG/PNG)
 * @param backgroundColor - Background color of the app bar
 * @param height - Height of the app bar
 */
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({
    Key? key,
    this.leadingImagePath,
    this.trailingImagePath,
    this.centerLogoImagePath,
    this.backgroundColor,
    this.height,
  }) : super(key: key);

  /// Path to the leading image displayed on the left side
  final String? leadingImagePath;

  /// Path to the trailing image displayed on the right side
  final String? trailingImagePath;

  /// Path to the center logo image displayed below the top row
  final String? centerLogoImagePath;

  /// Background color of the app bar
  final Color? backgroundColor;

  /// Height of the app bar
  final double? height;

  @override
  Size get preferredSize => Size.fromHeight(height ?? 108.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Color(0xFFFFFFFF),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: height ?? 108.h,
      flexibleSpace: Container(
        width: double.maxFinite,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: 12.h,
                right: 18.h,
                bottom: 12.h,
                left: 18.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (leadingImagePath != null)
                    Container(
                      margin: EdgeInsets.only(top: 4.h, left: 10.h),
                      child: CustomImageView(
                        imagePath: leadingImagePath!,
                        height: 10.h,
                        width: 26.h,
                      ),
                    )
                  else
                    SizedBox(width: 26.h),
                  if (trailingImagePath != null)
                    CustomImageView(
                      imagePath: trailingImagePath!,
                      height: 10.h,
                      width: 64.h,
                    )
                  else
                    SizedBox(width: 64.h),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            if (centerLogoImagePath != null)
              CustomImageView(
                imagePath: centerLogoImagePath!,
                height: 54.h,
                width: 68.h,
              ),
          ],
        ),
      ),
    );
  }
}
