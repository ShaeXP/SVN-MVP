import 'package:flutter/material.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/core/utils/image_constant.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';
import './custom_image_view.dart';

/**
 * CustomDropdown - A flexible dropdown component with form validation support
 * 
 * Features:
 * - Generic type support for different data types
 * - Form validation integration
 * - Customizable styling and dimensions
 * - Custom arrow icon support
 * - Responsive design with SizeUtils
 * 
 * @param items - List of dropdown items to display
 * @param onChanged - Callback function when selection changes
 * @param validator - Form validation function
 * @param value - Currently selected value
 * @param hintText - Placeholder text when no selection
 * @param width - Custom width for the dropdown
 * @param isEnabled - Whether the dropdown is enabled
 */
class CustomDropdown<T> extends StatelessWidget {
  CustomDropdown({
    Key? key,
    required this.items,
    required this.onChanged,
    this.validator,
    this.value,
    this.hintText,
    this.width,
    this.isEnabled,
  }) : super(key: key);

  /// List of dropdown items to display
  final List<DropdownMenuItem<T>> items;

  /// Callback function when selection changes
  final void Function(T?)? onChanged;

  /// Form validation function
  final String? Function(T?)? validator;

  /// Currently selected value
  final T? value;

  /// Placeholder text when no selection is made
  final String? hintText;

  /// Custom width for the dropdown
  final double? width;

  /// Whether the dropdown is enabled
  final bool? isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: (isEnabled ?? true) ? onChanged : null,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText ?? "Sort by...",
          hintStyle: TextStyleHelper.instance.body14RegularOpenSans
              .copyWith(color: appTheme.gray_700),
          contentPadding: EdgeInsets.only(
            top: 8.h,
            right: 32.h,
            bottom: 8.h,
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
          filled: true,
          fillColor: appTheme.white_A700,
        ),
        style: TextStyleHelper.instance.body14RegularOpenSans
            .copyWith(color: appTheme.gray_700),
        icon: Container(
          margin: EdgeInsets.only(right: 8.h),
          child: CustomImageView(
            imagePath: ImageConstant.imgArrowdown,
            height: 16.h,
            width: 16.h,
          ),
        ),
        isExpanded: true,
        dropdownColor: appTheme.white_A700,
      ),
    );
  }
}
