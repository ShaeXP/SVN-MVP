import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';
import './custom_image_view.dart';

/**
 * A customizable search input field widget with optional prefix icon and validation support.
 * 
 * This widget provides a search interface with configurable styling, placeholder text,
 * and validation capabilities. It uses TextFormField as the base component with
 * custom styling and responsive design.
 * 
 * @param controller TextEditingController for managing the search input
 * @param placeholder Placeholder text displayed when the field is empty
 * @param prefixIconPath Path to the prefix icon image (SVG, PNG, etc.)
 * @param backgroundColor Background color of the search field
 * @param borderRadius Border radius for rounded corners
 * @param textStyle Text style for the input text
 * @param placeholderStyle Text style for the placeholder text
 * @param validator Validation function for form validation
 * @param onChanged Callback function triggered when text changes
 * @param onSubmitted Callback function triggered when search is submitted
 * @param margin Margin around the search field
 * @param padding Internal padding of the search field
 * @param prefixIconSize Size of the prefix icon
 */
class CustomSearchView extends StatelessWidget {
  CustomSearchView({
    Key? key,
    this.controller,
    this.placeholder,
    this.prefixIconPath,
    this.backgroundColor,
    this.borderRadius,
    this.textStyle,
    this.placeholderStyle,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.margin,
    this.padding,
    this.prefixIconSize,
  }) : super(key: key);

  /// Controller for managing the search input text
  final TextEditingController? controller;

  /// Placeholder text displayed when the field is empty
  final String? placeholder;

  /// Path to the prefix icon image
  final String? prefixIconPath;

  /// Background color of the search field
  final Color? backgroundColor;

  /// Border radius for rounded corners
  final double? borderRadius;

  /// Text style for the input text
  final TextStyle? textStyle;

  /// Text style for the placeholder text
  final TextStyle? placeholderStyle;

  /// Validation function for form validation
  final String? Function(String?)? validator;

  /// Callback function triggered when text changes
  final Function(String)? onChanged;

  /// Callback function triggered when search is submitted
  final Function(String)? onSubmitted;

  /// Margin around the search field
  final EdgeInsets? margin;

  /// Internal padding of the search field
  final EdgeInsets? padding;

  /// Size of the prefix icon
  final double? prefixIconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.h),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        style: textStyle ??
            TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700),
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText:
              placeholder ?? "Search recordings by title or transcript...",
          hintStyle: placeholderStyle ??
              TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_700),
          prefixIcon: prefixIconPath != null
              ? Container(
                  padding: EdgeInsets.all(12.h),
                  child: CustomImageView(
                    imagePath: prefixIconPath!,
                    height: prefixIconSize ?? 20.h,
                    width: prefixIconSize ?? 20.h,
                  ),
                )
              : null,
          filled: true,
          fillColor: backgroundColor ?? Color(0xFFF3F4F6),
          contentPadding:
              padding ?? EdgeInsets.fromLTRB(28.h, 16.h, 12.h, 16.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.h),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.h),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.h),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
        ),
      ),
    );
  }
}
