import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './controller/preview_health_check_controller.dart';

class PreviewHealthCheckScreen extends GetWidget<PreviewHealthCheckController> {
  const PreviewHealthCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
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
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Text(
                  'Preview OK',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
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
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 16.0),

                    // Flutter version
                    Obx(() => _buildInfoRow(
                          'Flutter Version:',
                          controller.flutterVersion.value,
                        )),

                    SizedBox(height: 8.0),

                    // Dart version
                    Obx(() => _buildInfoRow(
                          'Dart Version:',
                          controller.dartVersion.value,
                        )),

                    SizedBox(height: 8.0),

                    // Main execution status
                    Obx(() => _buildInfoRow(
                          'main() Executed:',
                          controller.mainExecuted.value
                              ? '✅ SUCCESS'
                              : '❌ FAILED',
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                  ),
                  child: Text(
                    'Continue to App',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.0),

              // Additional info
              Text(
                'Development Health Check',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.h,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'Courier',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }
}