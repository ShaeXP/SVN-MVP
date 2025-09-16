import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import './controller/recording_library_controller.dart';
import './widgets/recording_item_widget.dart';

class RecordingLibraryScreen extends StatelessWidget {
  RecordingLibraryScreen({Key? key}) : super(key: key);

  final RecordingLibraryController controller =
      Get.put(RecordingLibraryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: appTheme.color281E12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            spacing: 4.h,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.onRefresh,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      spacing: 16.h,
                      children: [
                        _buildHeaderSection(),
                        _buildSearchSection(),
                        _buildFilterSection(),
                        _buildErrorBanner(),
                        _buildRecordingsListSection(),
                        _buildSeparatorLine(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 1,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        Get.toNamed(AppRoutes.homeScreen);
        break;
      case 1:
        // Already on Recording Library Screen
        break;
      case 2:
        Get.toNamed(AppRoutes.settingsScreen);
        break;
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 10.h),
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        border: Border(
          bottom: BorderSide(
            color: appTheme.gray_300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.h, left: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgGroup,
                  height: 10.h,
                  width: 26.h,
                ),
                CustomImageView(
                  imagePath: ImageConstant.imgGroupGray900,
                  height: 10.h,
                  width: 64.h,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 18.h),
            child: Text(
              'Recording Library',
              style: TextStyleHelper.instance.headline24BoldQuattrocento
                  .copyWith(height: 1.125),
            ),
          ),
          Obx(() {
            final count = controller
                .recordingLibraryModelObj.value.recordingItemList.length;
            return Text(
              '$count recordings found',
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_700, height: 1.43),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return CustomSearchView(
      controller: controller.searchController,
      placeholder: 'Search recordings by title or transcript...',
      prefixIconPath: ImageConstant.imgSearch,
      backgroundColor: appTheme.gray_100,
      borderRadius: 10.h,
      margin: EdgeInsets.symmetric(horizontal: 16.h),
      padding: EdgeInsets.fromLTRB(28.h, 16.h, 12.h, 16.h),
      onChanged: (value) => controller.onSearchTextChanged(),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.h),
      child: Row(
        children: [
          Expanded(
            flex: 34,
            child: CustomDropdown<String>(
              items: [
                DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                DropdownMenuItem(value: 'title', child: Text('By Title')),
              ],
              onChanged: (value) {
                // TODO: Implement sorting functionality
              },
              hintText: 'Sort by...',
              value: null,
            ),
          ),
          SizedBox(width: 10.h),
          CustomButton(
            text: 'Refresh',
            leftIcon: ImageConstant.imgRotateCcw,
            onPressed: controller.onRefresh,
            backgroundColor: appTheme.white_A700,
            textColor: appTheme.gray_700,
            borderColor: appTheme.gray_300,
            borderWidth: 1,
            borderRadius: 6.h,
            variant: CustomButtonVariant.outlined,
            width: null,
            height: 40.h,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Obx(() {
      if (!controller.hasError) return SizedBox.shrink();

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h),
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(8.h),
          border: Border.all(color: appTheme.red_400),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: appTheme.red_400,
              size: 20.h,
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: Text(
                controller.errorMessage,
                style: TextStyleHelper.instance.body14RegularOpenSans
                    .copyWith(color: appTheme.red_700),
              ),
            ),
            TextButton(
              onPressed: controller.onRetry,
              child: Text(
                'Retry',
                style: TextStyleHelper.instance.body14SemiBoldOpenSans
                    .copyWith(color: appTheme.red_700),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecordingsListSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.h),
      child: Obx(() {
        // Show loading indicator during refresh
        if (controller.isRefreshing) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: CircularProgressIndicator(
                color: appTheme.blue_200_01,
              ),
            ),
          );
        }

        // Check if library is empty
        if (controller.isLibraryEmpty) {
          return _buildEmptyState();
        }

        // Show recordings list using the reactive RxList
        final recordings =
            controller.recordingLibraryModelObj.value.recordingItemList;

        return Column(
          spacing: 16.h,
          children: recordings
              .map((item) => RecordingItemWidget(
                    recording: item,
                    onTap: () {
                      controller.onOpenNotePressed(item.id);
                    },
                    onDelete: () {
                      controller.onDeletePressed(item.id);
                    },
                  ))
              .toList(),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20.h,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgImgEmptystate,
            height: 120.h,
            width: 120.h,
          ),
          Column(
            spacing: 8.h,
            children: [
              Text(
                'No notes yet',
                style: TextStyleHelper.instance.title20BoldQuattrocento
                    .copyWith(color: appTheme.gray_900),
                textAlign: TextAlign.center,
              ),
              Text(
                'Record or upload to see them here',
                style: TextStyleHelper.instance.body14RegularOpenSans
                    .copyWith(color: appTheme.gray_700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          CustomButton(
            text: 'Refresh',
            onPressed: controller.onRefresh,
            backgroundColor: appTheme.blue_200_01,
            textColor: appTheme.cyan_900,
            borderRadius: 6.h,
            width: 120.h,
            height: 40.h,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatorLine() {
    return Container(
      height: 1.h,
      width: double.infinity,
      color: appTheme.gray_200,
    );
  }
}