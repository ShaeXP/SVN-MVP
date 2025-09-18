import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/recording_summary_model.dart';

class ActionChipWidget extends StatelessWidget {
  final ActionChipModel actionChip;
  final VoidCallback onTap;

  ActionChipWidget({
    Key? key,
    required this.actionChip,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          border: Border.all(
            color: appTheme.gray_300,
            width: 1.h,
          ),
          borderRadius: BorderRadius.circular(6.h),
        ),
        padding: EdgeInsets.fromLTRB(18.h, 8.h, 18.h, 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: actionChip.iconPath?.value ?? '',
              height: 16.h,
              width: 16.h,
            ),
            SizedBox(width: 8.h),
            Text(
              actionChip.text?.value ?? '',
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_900, height: 1.43),
            ),
          ],
        ),
      ),
    );
  }
}
