import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ActionItemWidget extends StatelessWidget {
  final int index;
  final String action;

  const ActionItemWidget({
    Key? key,
    required this.index,
    required this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.h),
      decoration: BoxDecoration(
        color: appTheme.orange_50,
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: appTheme.orange_200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.h,
            height: 24.h,
            decoration: BoxDecoration(
              color: appTheme.orange_600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                    color: appTheme.white_A700, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              action,
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
