import 'package:lashae_s_application/core/app_export.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_view.dart';
import '../../ui/widgets/unified_status_chip.dart';
import '../../ui/widgets/pipeline_ring_lottie.dart';
import '../../dev/dev_pipeline_sim.dart';
import './controller/file_upload_controller.dart';

class FileUploadScreen extends GetWidget<FileUploadController> {
  FileUploadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            // Custom header section
            _buildHeaderSection(),
            
            // Progress banner
            Obx(() {
              if (controller.currentRecordingId == null) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 80, // Give it a maximum height
                child: UnifiedPipelineBanner(recordingId: controller.currentRecordingId!),
              );
            }),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    _buildUploadSection(),
                    SizedBox(height: 32.h),
                    _buildInstructionsSection(),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),

            // Error banner (conditionally shown)
            Obx(() => controller.showErrorBanner.value
                ? Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.h),
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: appTheme.redCustom.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.h),
                      border: Border.all(color: appTheme.red_400, width: 1.h),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: appTheme.red_400, size: 20.h),
                        SizedBox(width: 8.h),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyleHelper
                                .instance.body12RegularOpenSans
                                .copyWith(color: appTheme.red_400),
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.dismissError,
                          child: Icon(Icons.close,
                              color: appTheme.red_400, size: 20.h),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink()),

            SizedBox(height: 16.h),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 0,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        border: Border(
          bottom: BorderSide(
            color: appTheme.color7FDEE1,
            width: 1.h,
          ),
        ),
      ),
      child: Column(
        children: [
          // Status bar section with icons
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 18.h,
              vertical: 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 4.h, left: 10.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgGroup,
                    height: 10.h,
                    width: 26.h,
                  ),
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgGroupGray900,
                  height: 10.h,
                  width: 64.h,
                ),
              ],
            ),
          ),

          // Header with title, bell icon, and profile
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.h, 0, 16.h, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(id: 1),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: appTheme.gray_700,
                    size: 24.h,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 4.h),
                  child: kDebugMode
                      ? GestureDetector(
                          onLongPress: () {
                            if (controller.currentRecordingId != null) {
                              devSimulatePipeline(controller.currentRecordingId!);
                            }
                          },
                          child: Text(
                            'Upload Audio',
                            style: TextStyleHelper.instance.title18BoldQuattrocento
                                .copyWith(height: 1.11),
                          ),
                        )
                      : Text(
                          'Upload Audio',
                          style: TextStyleHelper.instance.title18BoldQuattrocento
                              .copyWith(height: 1.11),
                        ),
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgIconBell,
                  height: 22.h,
                  width: 22.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          // Upload area
          Obx(() => Container(
                width: double.infinity,
                padding: EdgeInsets.all(48.h),
                decoration: BoxDecoration(
                  color: appTheme.white_A700,
                  borderRadius: BorderRadius.circular(16.h),
                  border: Border.all(
                    color: controller.isUploading.value
                        ? appTheme.blue_200_01
                        : appTheme.gray_300,
                    width: 2.h,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.color1F0C17,
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 96.h,
                      width: 96.h,
                      decoration: BoxDecoration(
                        color: controller.isUploading.value
                            ? appTheme.blue_200_01.withAlpha(26)
                            : appTheme.blue_200_01,
                        borderRadius: BorderRadius.circular(48.h),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Obx(() {
                            print('DEBUG FILE UPLOAD UI: isUploading = ${controller.isUploading.value}');
                            if (controller.isUploading.value) {
                              print('DEBUG FILE UPLOAD UI: Showing progress indicator');
                              return PipelineRingLottie(
                                progress: controller.uploadProgressPercent.value / 100,
                                stage: controller.uploadStage.value,
                              );
                            } else {
                              print('DEBUG FILE UPLOAD UI: Showing upload icon');
                              return CustomImageView(
                                imagePath: ImageConstant.imgUpload,
                                height: 40.h,
                                width: 40.h,
                              );
                            }
                          }),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Text(
                      controller.isUploading.value
                          ? 'Uploading your audio file...'
                          : 'Upload Audio File',
                      style: TextStyleHelper.instance.title20BoldQuattrocento
                          .copyWith(height: 1.15),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      controller.isUploading.value
                          ? (controller.uploadProgress.value.isNotEmpty 
                              ? controller.uploadProgress.value 
                              : 'Processing...')
                          : 'Select .webm, .m4a, .wav, .mp3, or .aac files',
                      style: TextStyleHelper.instance.body14RegularOpenSans
                          .copyWith(
                        color: appTheme.gray_700,
                        height: 1.43,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 24.h),

                    // Upload button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isUploading.value
                            ? null
                            : controller.onSelectFilePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isUploading.value
                              ? appTheme.gray_300
                              : appTheme.blue_200_01,
                          padding: EdgeInsets.symmetric(
                            horizontal: 30.h,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          controller.isUploading.value
                              ? 'Processing...'
                              : 'Choose File',
                          style: TextStyleHelper.instance.body14RegularOpenSans
                              .copyWith(
                            color: appTheme.cyan_900,
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.blue_200_01.withAlpha(13),
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(
          color: appTheme.blue_200_01.withAlpha(51),
          width: 1.h,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: appTheme.blue_200_01,
                size: 20.h,
              ),
              SizedBox(width: 8.h),
              Text(
                'How it works',
                style: TextStyleHelper.instance.title16BoldQuattrocento
                    .copyWith(color: appTheme.blue_200_01),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInstructionStep(
              '1', 'Select your audio file (.webm, .m4a, .wav, .mp3, .aac)'),
          SizedBox(height: 8.h),
          _buildInstructionStep('2', 'File will be uploaded to secure storage'),
          SizedBox(height: 8.h),
          _buildInstructionStep(
              '3', 'AI will transcribe and summarize your audio'),
          SizedBox(height: 8.h),
          _buildInstructionStep('4', 'View results in your library'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.h,
          height: 20.h,
          decoration: BoxDecoration(
            color: appTheme.blue_200_01,
            borderRadius: BorderRadius.circular(10.h),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyleHelper.instance.body12RegularOpenSans.copyWith(
                color: appTheme.white_A700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.h),
        Expanded(
          child: Text(
            text,
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700),
          ),
        ),
      ],
    );
  }

  void _onBottomNavigationChanged(int index) {
    // Disable navigation during upload
    if (controller.isUploading.value) {
      return;
    }

    switch (index) {
      case 0:
        Get.toNamed(Routes.home, id: 1);
        break;
      case 1:
        Get.toNamed(Routes.recordingLibrary, id: 1);
        break;
      case 2:
        Get.toNamed(Routes.settings, id: 1);
        break;
    }
  }
}
