import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class KeyPointWidget extends StatelessWidget {
  final String keypoint;

  const KeyPointWidget({
    Key? key,
    required this.keypoint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.h,
            height: 6.h,
            decoration: BoxDecoration(
              color: appTheme.green_600,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              keypoint,
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
