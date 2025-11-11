import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:lashae_s_application/core/utils/image_constant.dart';
import 'package:lashae_s_application/theme/app_theme.dart';
import 'package:lashae_s_application/theme/custom_text_style.dart';
import './custom_image_view.dart';

/**
 * CustomDropdown - A flexible dropdown component with form validation support
 * 
 * Features:
 * - Customizable styling with border colors and border radius
 * - Form validation integration
 * - Dropdown arrow icon
 * - Support for different states (enabled, disabled, error)
 * - Flexible item rendering
 */
class CustomDropdown<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? hintText; // Legacy support
  final String? label;
  final String? errorText;
  final bool enabled;
  final Color? borderColor;
  final Color? errorBorderColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomDropdown({
    Key? key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.hintText, // Legacy support
    this.label,
    this.errorText,
    this.enabled = true,
    this.borderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.padding,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final currentBorderColor = hasError 
        ? (errorBorderColor ?? appTheme.red_400)
        : (borderColor ?? appTheme.gray_300);

    // Use hintText if provided (legacy), otherwise use hint
    final displayHint = hintText ?? hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
              color: appTheme.gray_900,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          padding: EdgeInsets.only(
            top: 8.h,
            right: 32.h,
            bottom: 8.h,
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: enabled ? onChanged : null,
              hint: displayHint != null
                  ? Text(
                      displayHint,
                      style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                        color: appTheme.gray_500,
                      ),
                    )
                  : null,
              items: items,
              isExpanded: true,
              icon: Container(
                margin: EdgeInsets.only(right: 8.h),
                child: CustomImageView(
                  imagePath: ImageConstant.imgArrowdown,
                  height: 16.h,
                  width: 16.h,
                ),
              ),
              style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                color: appTheme.gray_900,
              ),
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
    );
  }
}
