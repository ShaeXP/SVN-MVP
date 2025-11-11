import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './controller/preview_health_check_controller.dart';

class PreviewHealthCheckScreen extends GetWidget<PreviewHealthCheckController> {
  const PreviewHealthCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: 20.h,
            vertical: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main status indicator
              Container(
                padding: EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Text(
                  'Preview OK',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 32.fSize,
                  ),
                ),
              ),

              SizedBox(height: 40.0),

              // Technical information section
              Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 16.0),

                    // Flutter version
                    Obx(() => _buildInfoRow(context,
                          'Flutter Version:',
                          controller.flutterVersion.value,
                        )),

                    SizedBox(height: 8.0),

                    // Dart version
                    Obx(() => _buildInfoRow(context,
                          'Dart Version:',
                          controller.dartVersion.value,
                        )),

                    SizedBox(height: 8.0),

                    // Main execution status
                    Obx(() => _buildInfoRow(
                          'main() Executed:',
                          controller.mainExecuted.value
                              ? 'âœ… SUCCESS'
                              : 'âŒ FAILED',
                        )),

                    SizedBox(height: 8.0),

                    // Timestamp
                    Obx(() => _buildInfoRow(
                          'Initialized At:',
                          controller.initTimestamp.value,
                        )),
                  ],
                ),
              ),

              SizedBox(height: 32.0),

              // Navigation button
              SizedBox(
                width: double.maxFinite,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: controller.navigateToMain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                  ),
                  child: Text(
                    'Continue to App',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.0),

              // Additional info
              Text(
                'Development Health Check',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.h,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'Courier',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }
}
