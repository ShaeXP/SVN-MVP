import 'package:lashae_s_application/app/routes/app_pages.dart';
import 'package:lashae_s_application/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import './controller/settings_controller.dart';

class SettingsScreen extends GetWidget<SettingsController> {
  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700,
      body: Container(
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          boxShadow: [
            BoxShadow(
              color: appTheme.color281E12,
              blurRadius: 6.h,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppBarSection(),
              _buildMainContentSection(),
              _buildSettingsGridSection(),
              _buildExpandableSettingsSection(),
              _buildAccountInformationSection(),
              _buildUserIdSection(),
              _buildAdditionalSettingsSection(),
              _buildResetSettingsSection(),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: 2,
        onChanged: (index) {
          _onBottomNavigationChanged(index);
        },
      ),
    );
  }

  void _onBottomNavigationChanged(int index) {
    switch (index) {
      case 0:
        Get.toNamed(Routes.homeScreen);
        break;
      case 1:
        Get.toNamed(Routes.recordingLibraryScreen);
        break;
      case 2:
        // Already on Settings Screen
        break;
    }
  }

  Widget _buildAppBarSection() {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        border: Border(
          bottom: BorderSide(
            color: appTheme.gray_300,
            width: 1.h,
          ),
        ),
      ),
      child: Column(
        spacing: 22.h,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 4.h, left: 10.h),
                  child: GestureDetector(
                    onLongPress: () => controller.onAppLogoLongPress(),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgGroup,
                      height: 10.h,
                      width: 26.h,
                    ),
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
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            child: Text(
              'Settings',
              style: TextStyleHelper.instance.title18BoldQuattrocento
                  .copyWith(height: 1.11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 32.h, left: 24.h),
          child: Text(
            'Settings',
            style: TextStyleHelper.instance.headline30BoldQuattrocento
                .copyWith(height: 1.13),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 8.h, left: 24.h, right: 24.h),
          child: Text(
            'Customize your SmartVoiceNotes experience and manage your account preferences.',
            style: TextStyleHelper.instance.title16RegularOpenSans
                .copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGridSection() {
    return Container(
      margin: EdgeInsets.only(top: 12.h, left: 22.h, right: 22.h),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.h,
        childAspectRatio: 1.2,
        children: [
          _buildGridSettingCard(
            iconPath: ImageConstant.imgPaintbrush,
            backgroundColor: appTheme.colorF51988,
            title: 'Theme',
            subtitle: 'Light/Dark mode',
          ),
          _buildGridSettingCard(
            iconPath: ImageConstant.imgBrain,
            backgroundColor: appTheme.color8110B9,
            title: 'AI Settings',
            subtitle: 'Voice & summaries',
          ),
          _buildGridSettingCard(
            iconPath: ImageConstant.imgBell,
            backgroundColor: appTheme.color281F1E,
            title: 'Notifications',
            subtitle: 'Alerts & updates',
          ),
          _buildGridSettingCard(
            iconPath: ImageConstant.imgIconBilling,
            backgroundColor: appTheme.colorF16366,
            title: 'Billing',
            subtitle: 'Usage & plans',
          ),
        ],
      ),
    );
  }

  Widget _buildGridSettingCard({
    required String iconPath,
    required Color backgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.white_A700,
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.color1F0C17,
            blurRadius: 1.h,
          ),
        ],
      ),
      padding: EdgeInsets.all(16.h),
      child: Column(
        spacing: 10.h,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconButton(
            iconPath: iconPath,
            backgroundColor: backgroundColor,
            size: 40.h,
            iconSize: 24.h,
          ),
          Text(
            title,
            style: TextStyleHelper.instance.title18BoldQuattrocento
                .copyWith(height: 1.11),
          ),
          Text(
            subtitle,
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700, height: 1.43),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSettingsSection() {
    return Container(
      margin: EdgeInsets.only(top: 16.h, left: 14.h, right: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 8.h),
      child: Column(
        spacing: 16.h,
        children: [
          _buildExpandableSettingItem(
            iconPath: ImageConstant.imgPaintbrush,
            backgroundColor: appTheme.colorF51988,
            title: 'Appearance',
            subtitle: 'Theme and display preferences',
            onTap: () => controller.onAppearanceTap(),
          ),
          _buildExpandableSettingItem(
            iconPath: ImageConstant.imgBrain,
            backgroundColor: appTheme.color8110B9,
            title: 'AI Preferences',
            subtitle: 'Customize AI behavior and responses',
            onTap: () => controller.onAIPreferencesTap(),
          ),
          _buildExpandableSettingItem(
            iconPath: ImageConstant.imgBell,
            backgroundColor: appTheme.color281F1E,
            title: 'Notifications',
            subtitle: 'Manage alerts and updates',
            onTap: () => controller.onNotificationsTap(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSettingItem({
    required String iconPath,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          borderRadius: BorderRadius.circular(10.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.color1F0C17,
              blurRadius: 1.h,
            ),
          ],
        ),
        padding: EdgeInsets.all(16.h),
        child: Row(
          spacing: 14.h,
          children: [
            CustomIconButton(
              iconPath: iconPath,
              backgroundColor: backgroundColor,
              size: 40.h,
              iconSize: 24.h,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.title16BoldQuattrocento
                        .copyWith(height: 1.13),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyleHelper.instance.body14RegularOpenSans
                        .copyWith(color: appTheme.gray_700, height: 1.43),
                  ),
                ],
              ),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgArrowdown,
              height: 20.h,
              width: 20.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInformationSection() {
    return Container(
      margin: EdgeInsets.only(top: 18.h, left: 14.h, right: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14.h,
        children: [
          Text(
            'Account Information',
            style: TextStyleHelper.instance.title20BoldQuattrocento
                .copyWith(height: 1.15),
          ),
          Text(
            'Manage your account details and preferences',
            style: TextStyleHelper.instance.title16RegularOpenSans
                .copyWith(height: 1.38),
          ),
          Container(
            decoration: BoxDecoration(
              color: appTheme.white_A700,
              borderRadius: BorderRadius.circular(10.h),
              boxShadow: [
                BoxShadow(
                  color: appTheme.color1F0C17,
                  blurRadius: 1.h,
                ),
              ],
            ),
            padding: EdgeInsets.all(16.h),
            child: Row(
              spacing: 14.h,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgRectangle56x56,
                  height: 56.h,
                  width: 56.h,
                  radius: BorderRadius.circular(28.h),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.settingsModelObj.value.userName?.value ??
                            'Jane Smith',
                        style: TextStyleHelper.instance.title16RegularOpenSans
                            .copyWith(color: appTheme.gray_900, height: 1.38),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        controller.settingsModelObj.value.userEmail?.value ??
                            'demo@example.com',
                        style: TextStyleHelper.instance.body14RegularOpenSans
                            .copyWith(color: appTheme.gray_700, height: 1.43),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        controller.settingsModelObj.value.userId?.value ??
                            'ID: 56d3e15c...',
                        style: TextStyleHelper.instance.body12RegularOpenSans
                            .copyWith(color: appTheme.gray_700, height: 1.42),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            spacing: 16.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Profile',
                  leftIcon: ImageConstant.imgPencil,
                  onPressed: () => controller.onEditProfileTap(),
                  backgroundColor: appTheme.white_A700,
                  textColor: appTheme.blue_200_01,
                  borderColor: appTheme.blue_200_01,
                  borderWidth: 1,
                  borderRadius: 6.h,
                  variant: CustomButtonVariant.outlined,
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Sign Out',
                  leftIcon: ImageConstant.imgLogOut,
                  onPressed: () => controller.onSignOutPressed(),
                  backgroundColor: appTheme.red_400,
                  textColor: appTheme.white_A700,
                  borderRadius: 6.h,
                  variant: CustomButtonVariant.filled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdSection() {
    return Container(
      margin: EdgeInsets.only(top: 16.h, left: 22.h, right: 22.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(10.h),
      ),
      padding: EdgeInsets.all(16.h),
      child: Row(
        spacing: 12.h,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgInfo,
            height: 20.h,
            width: 20.h,
          ),
          Expanded(
            child: Text(
              'User ID (for development): 56d3e15c-74e9-488c-ae32-75c460a23972',
              style: TextStyleHelper.instance.body14RegularOpenSans
                  .copyWith(color: appTheme.gray_900, height: 1.43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettingsSection() {
    return Container(
      margin: EdgeInsets.only(top: 16.h, left: 14.h, right: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 8.h),
      child: Column(
        spacing: 16.h,
        children: [
          Obx(() => ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.additionalSettings.length,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final setting = controller.additionalSettings[index];
                  return _buildAdditionalSettingItem(
                    iconPath: setting.iconPath?.value ?? '',
                    backgroundColor: _getBackgroundColor(
                        setting.backgroundColor?.value ?? ''),
                    title: setting.title?.value ?? '',
                    subtitle: setting.subtitle?.value ?? '',
                    onTap: () => controller.onAdditionalSettingTap(index),
                  );
                },
              )),
          _buildAdditionalSettingItem(
            iconPath: ImageConstant.imgContainerOrange900,
            backgroundColor: appTheme.color16F973,
            title: 'Export Preferences',
            subtitle: 'Configure default export settings',
            onTap: () => controller.onExportPreferencesTap(),
          ),
          _buildAdditionalSettingItem(
            iconPath: ImageConstant.imgShield,
            backgroundColor: appTheme.color44EF44,
            title: 'Privacy & Security',
            subtitle: 'Control your data and privacy settings',
            onTap: () => controller.onPrivacySecurityTap(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettingItem({
    required String iconPath,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.white_A700,
          borderRadius: BorderRadius.circular(10.h),
          boxShadow: [
            BoxShadow(
              color: appTheme.color1F0C17,
              blurRadius: 1.h,
            ),
          ],
        ),
        padding: EdgeInsets.all(16.h),
        child: Row(
          spacing: 16.h,
          children: [
            CustomIconButton(
              iconPath: iconPath,
              backgroundColor: backgroundColor,
              size: 40.h,
              iconSize: 24.h,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.title16BoldQuattrocento
                        .copyWith(height: 1.13),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyleHelper.instance.body14RegularOpenSans
                        .copyWith(color: appTheme.gray_700, height: 1.43),
                  ),
                ],
              ),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgArrowdown,
              height: 20.h,
              width: 20.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSettingsSection() {
    return Container(
      margin: EdgeInsets.only(top: 20.h, left: 14.h, right: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Settings',
            style: TextStyleHelper.instance.title20BoldQuattrocento
                .copyWith(height: 1.15),
          ),
          Container(
            margin: EdgeInsets.only(top: 4.h),
            child: Text(
              'Restore all settings to their default values',
              style: TextStyleHelper.instance.title16RegularOpenSans
                  .copyWith(height: 1.38),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 14.h),
            width: double.infinity,
            child: CustomButton(
              text: 'Reset to Defaults',
              leftIcon: ImageConstant.imgRotateCcw,
              onPressed: () => controller.onResetToDefaultsTap(),
              backgroundColor: appTheme.white_A700,
              textColor: appTheme.gray_900,
              borderColor: appTheme.gray_300,
              borderWidth: 1,
              borderRadius: 6.h,
              variant: CustomButtonVariant.outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 48.h),
          child: CustomImageView(
            imagePath: ImageConstant.imgImageGray500,
            height: 48.h,
            width: 48.h,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 8.h),
          child: Text(
            'Version 2.1.0',
            style: TextStyleHelper.instance.body14RegularOpenSans
                .copyWith(color: appTheme.gray_700, height: 1.43),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.h),
          child: Row(
            spacing: 16.h,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_700, height: 1.42),
              ),
              Text(
                'â€¢',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_700, height: 1.42),
              ),
              Text(
                'Terms of Service',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_700, height: 1.42),
              ),
              Text(
                'â€¢',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_700, height: 1.42),
              ),
              Text(
                'Support',
                style: TextStyleHelper.instance.body12RegularOpenSans
                    .copyWith(color: appTheme.gray_700, height: 1.42),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 12.h, bottom: 56.h),
          child: Text(
            'Â© 2025 SmartVoiceNotes. All rights reserved.',
            style: TextStyleHelper.instance.body12RegularOpenSans
                .copyWith(color: appTheme.gray_700, height: 1.42),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(String colorString) {
    switch (colorString) {
      case '#19a855f7':
        return Color(0xF7A855F7);
      case '#193b82f6':
        return Color(0xF63B82F6);
      case '#196366f1':
        return Color(0xF16366F1);
      default:
        return Color(0xF51988CA);
    }
  }
}
