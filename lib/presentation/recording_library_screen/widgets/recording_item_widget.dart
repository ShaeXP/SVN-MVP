import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';
import '../../../widgets/custom_image_view.dart';

class RecordingItemWidget extends StatelessWidget {
  final RecordingItem recording;
  final VoidCallback onTap;

  RecordingItemWidget({
    Key? key,
    required this.recording,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          borderRadius: BorderRadius.circular(8.h),
          border: Border.all(
            color: appTheme.gray_300,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Recording icon/thumbnail
            Container(
              height: 56.h,
              width: 56.h,
              decoration: BoxDecoration(
                color: appTheme.gray_100,
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: CustomImageView(
                imagePath: ImageConstant.imgRectangle56x56,
                height: 56.h,
                width: 56.h,
                fit: BoxFit.cover,
                radius: BorderRadius.circular(8.h),
              ),
            ),

            SizedBox(width: 12.h),

            // Recording details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recording.title,
                    style: TextStyleHelper.instance.title16SemiBoldOpenSans
                        .copyWith(height: 1.5),
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Date
                  Text(
                    recording.date,
                    style:
                        TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                      color: appTheme.gray_700,
                      height: 1.43,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Duration
                  Text(
                    recording.duration,
                    style:
                        TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                      color: appTheme.gray_500,
                      height: 1.17,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.h),

            // More options button
            CustomImageView(
              imagePath: ImageConstant.imgSquare,
              height: 24.h,
              width: 24.h,
            ),
          ],
        ),
      ),
    );
  }
}
