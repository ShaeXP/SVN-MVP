import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/pipeline_tracker.dart';
import '../core/app_export.dart';

class PipelineProgressIndicator extends StatelessWidget {
  const PipelineProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tracker = PipelineTracker.I;
      final progress = tracker.progressPercentage;
      final stageLabel = tracker.stageLabel;
      final isError = tracker.status.value == PipeStage.error;
      print('DEBUG PipelineProgressIndicator: progress=$progress, stage=$stageLabel, isError=$isError');
      
      return Container(
        width: 200.h,
        height: 200.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 200.h,
              height: 200.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError ? appTheme.red_100 : appTheme.blue_50,
                border: Border.all(
                  color: isError ? appTheme.red_300 : appTheme.blue_200,
                  width: 2.h,
                ),
              ),
            ),
            
            // Progress ring
            SizedBox(
              width: 200.h,
              height: 200.h,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8.h,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isError ? appTheme.red_400 : appTheme.blue_400,
                ),
              ),
            ),
            
            // Center content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Percentage
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyleHelper.instance.title24BoldOpenSans.copyWith(
                    color: isError ? appTheme.red_600 : appTheme.blue_600,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Stage label
                Text(
                  stageLabel,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularOpenSans.copyWith(
                    color: isError ? appTheme.red_500 : appTheme.gray_600,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Error message if applicable
                if (isError && tracker.message.value.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: appTheme.red_50,
                      borderRadius: BorderRadius.circular(4.h),
                      border: Border.all(color: appTheme.red_200),
                    ),
                    child: Text(
                      tracker.message.value,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                        color: appTheme.red_600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}
