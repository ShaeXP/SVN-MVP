import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/recording_item.dart';
import '../../../widgets/custom_image_view.dart';

class RecordingItemWidget extends StatelessWidget {
  final RecordingItem recording;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  RecordingItemWidget({
    Key? key,
    required this.recording,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('recording_${recording.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: onDelete != null ? (_) => onDelete!() : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.h),
        decoration: BoxDecoration(
          color: appTheme.red_400,
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Icon(
          Icons.delete,
          color: appTheme.white_A700,
          size: 24.h,
        ),
      ),
      child: GestureDetector(
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

                    // Date and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recording.date,
                            style: TextStyleHelper
                                .instance.body14RegularOpenSans
                                .copyWith(
                              color: appTheme.gray_700,
                              height: 1.43,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Status badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.h,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor('ready'),
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: Text(
                            'Ready',
                            style: TextStyleHelper
                                .instance.body12RegularOpenSans
                                .copyWith(
                              color: appTheme.white_A700,
                              height: 1.17,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Duration (if available)
                    if (recording.duration.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        recording.duration,
                        style: TextStyleHelper.instance.body12RegularOpenSans
                            .copyWith(
                          color: appTheme.gray_500,
                          height: 1.17,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 12.h),

              // Delete button
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: EdgeInsets.all(8.h),
                    child: Icon(
                      Icons.delete_outline,
                      color: appTheme.gray_500,
                      size: 20.h,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return appTheme.orange_900;
      case 'transcribing':
        return appTheme.blue_200_01;
      case 'transcribed':
      case 'ready':
        return appTheme.green_600;
      case 'error':
        return appTheme.red_400;
      default:
        return appTheme.gray_500;
    }
  }
}
