import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';
import './custom_image_view.dart';

/**
 * CustomButton - A flexible button component that supports various styles, icons, and layouts
 * 
 * Features:
 * - Supports text-only and icon + text configurations
 * - Customizable colors, borders, and shadows
 * - Flexible width options (flex, fixed, or full width)
 * - Multiple button variants (filled, outlined, text)
 * - Responsive design with SizeUtils integration
 * 
 * @param text - Button text content
 * @param onPressed - Callback function when button is pressed
 * @param leftIcon - Optional icon path to display on the left side
 * @param backgroundColor - Background color of the button
 * @param textColor - Color of the button text
 * @param borderColor - Color of the button border
 * @param borderWidth - Width of the button border
 * @param borderRadius - Border radius for rounded corners
 * @param variant - Button style variant (filled, outlined, text)
 * @param width - Button width configuration
 * @param height - Button height
 * @param isEnabled - Whether the button is enabled or disabled
 * @param elevation - Shadow elevation for the button
 * @param fontSize - Font size for button text
 * @param fontWeight - Font weight for button text
 */
class CustomButton extends StatelessWidget {
  CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.leftIcon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.variant,
    this.width,
    this.height,
    this.isEnabled,
    this.elevation,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  /// Button text content
  final String text;

  /// Callback function when button is pressed
  final VoidCallback? onPressed;

  /// Optional icon path to display on the left side
  final String? leftIcon;

  /// Background color of the button
  final Color? backgroundColor;

  /// Color of the button text
  final Color? textColor;

  /// Color of the button border
  final Color? borderColor;

  /// Width of the button border
  final double? borderWidth;

  /// Border radius for rounded corners
  final double? borderRadius;

  /// Button style variant
  final CustomButtonVariant? variant;

  /// Button width configuration
  final double? width;

  /// Button height
  final double? height;

  /// Whether the button is enabled or disabled
  final bool? isEnabled;

  /// Shadow elevation for the button
  final double? elevation;

  /// Font size for button text
  final double? fontSize;

  /// Font weight for button text
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 44.h,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final ButtonStyle buttonStyle = _getButtonStyle();
    final Widget buttonChild = _buildButtonChild();

    switch (variant ?? CustomButtonVariant.filled) {
      case CustomButtonVariant.filled:
        return ElevatedButton(
          onPressed: (isEnabled ?? true) ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
      case CustomButtonVariant.outlined:
        return OutlinedButton(
          onPressed: (isEnabled ?? true) ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
      case CustomButtonVariant.text:
        return TextButton(
          onPressed: (isEnabled ?? true) ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        backgroundColor ?? Color(0xFF88CAF5),
      ),
      foregroundColor: WidgetStateProperty.all(
        textColor ?? Color(0xFF0A4D79),
      ),
      side: WidgetStateProperty.all(
        BorderSide(
          color: borderColor ?? appTheme.transparentCustom,
          width: borderWidth ?? 0,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 6.h),
        ),
      ),
      elevation: WidgetStateProperty.all(elevation ?? 0),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
          horizontal: 30.h,
          vertical: 12.h,
        ),
      ),
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildButtonChild() {
    if (leftIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: leftIcon!,
            height: 16.h,
            width: 16.h,
          ),
          SizedBox(width: 8.h),
          Flexible(
            child: _buildButtonText(),
          ),
        ],
      );
    } else {
      return _buildButtonText();
    }
  }

  Widget _buildButtonText() {
    return Text(
      text,
      style: TextStyleHelper.instance.textStyle18
          .copyWith(color: textColor ?? Color(0xFF0A4D79)),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Button style variants
enum CustomButtonVariant {
  filled,
  outlined,
  text,
}
