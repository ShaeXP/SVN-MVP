import 'package:flutter/material.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';

/**
 * CustomEditText - A reusable text input field component
 * 
 * This component provides a customizable text input field with support for:
 * - Different keyboard types (email, password, text)
 * - Password visibility toggle
 * - Form validation
 * - Consistent styling across the app
 * 
 * @param controller - TextEditingController for managing text input
 * @param hintText - Placeholder text displayed when field is empty
 * @param keyboardType - Type of keyboard to display (email, password, etc.)
 * @param obscureText - Whether to obscure text input (for passwords)
 * @param validator - Function to validate input text
 * @param enabled - Whether the field is enabled for input
 * @param maxLines - Maximum number of lines for text input
 * @param onChanged - Callback function when text changes
 * @param onTap - Callback function when field is tapped
 */
class CustomEditText extends StatelessWidget {
  CustomEditText({
    Key? key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText,
    this.validator,
    this.enabled,
    this.maxLines,
    this.onChanged,
    this.onTap,
  }) : super(key: key);

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final String? Function(String?)? validator;
  final bool? enabled;
  final int? maxLines;
  final Function(String)? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        obscureText: obscureText ?? false,
        enabled: enabled ?? true,
        maxLines: maxLines ?? 1,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        style: TextStyleHelper.instance.body14RegularOpenSans
            .copyWith(color: appTheme.gray_700),
        decoration: InputDecoration(
          hintText: hintText ?? "Enter text",
          hintStyle: TextStyleHelper.instance.body14RegularOpenSans
              .copyWith(color: appTheme.gray_700),
          filled: true,
          fillColor: appTheme.white_A700,
          contentPadding: EdgeInsets.only(
            top: 8.h,
            right: 16.h,
            bottom: 10.h,
            left: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.gray_300,
              width: 1.h,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.gray_300,
              width: 1.h,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.gray_300,
              width: 1.h,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.gray_300,
              width: 1.h,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.redCustom,
              width: 1.h,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.h),
            borderSide: BorderSide(
              color: appTheme.redCustom,
              width: 1.h,
            ),
          ),
        ),
      ),
    );
  }
}
