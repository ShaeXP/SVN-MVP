import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class SummaryLengthOptionWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  SummaryLengthOptionWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF1F9FE) : appTheme.white_A700,
          border: Border.all(
            color: isSelected ? Color(0xFF88CAF5) : appTheme.gray_300,
            width: 1.h,
          ),
          borderRadius: BorderRadius.circular(10.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.color1F0C17,
              offset: Offset(0, 0),
              blurRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            12.h, isSelected ? 16.h : 18.h, 12.h, isSelected ? 16.h : 18.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                  color: isSelected ? Color(0xFF19191F) : appTheme.gray_900,
                  height: 1.43),
            ),
            Text(
              subtitle,
              style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                  color: isSelected ? Color(0xFF19191F) : appTheme.gray_700,
                  height: 1.42),
            ),
          ],
        ),
      ),
    );
  }
}
