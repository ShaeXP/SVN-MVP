import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';

/**
 * CustomEditText - A reusable text input field component
 * 
 * This component provides a customizable text input field with support for:
 * - Different keyboard types (email, password, text)
 * - Form validation with error states
 * - Custom styling and theming
 * - Placeholder text and labels
 * - Prefix and suffix icons
 */
class CustomEditText extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Color? borderColor;
  final Color? errorBorderColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  
  // Legacy support for validator
  final String? Function(String?)? validator;

  const CustomEditText({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.borderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.validator, // Legacy support
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final currentBorderColor = hasError 
        ? (errorBorderColor ?? appTheme.red_400)
        : (borderColor ?? appTheme.gray_300);

    return Container(
      margin: margin ?? EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            Text(
              labelText!,
              style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                color: appTheme.gray_900,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          Container(
            padding: EdgeInsets.only(
              top: 8.h,
              right: 16.h,
              bottom: 10.h,
              left: 16.h,
            ),
            decoration: BoxDecoration(
              color: enabled ? appTheme.white_A700 : appTheme.gray_100,
              borderRadius: BorderRadius.circular(borderRadius ?? 6.h),
              border: Border.all(
                color: currentBorderColor,
                width: 1.h,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              enabled: enabled,
              maxLines: maxLines,
              maxLength: maxLength,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              focusNode: focusNode,
              style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                color: appTheme.gray_900,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                  color: appTheme.gray_500,
                ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          if (hasError) ...[
            SizedBox(height: 4.h),
            Text(
              errorText!,
              style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                color: appTheme.red_400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
