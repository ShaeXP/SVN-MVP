import 'package:get/get.dart';
import '../../../core/app_export.dart';

/// This class is used for individual setting items in the [SettingsScreen] screen with GetX.

class SettingItemModel {
  Rx<String>? iconPath;
  Rx<String>? backgroundColor;
  Rx<String>? title;
  Rx<String>? subtitle;
  Rx<bool>? isExpandable;

  SettingItemModel({
    this.iconPath,
    this.backgroundColor,
    this.title,
    this.subtitle,
    this.isExpandable,
  }) {
    isExpandable = isExpandable ?? true.obs;
  }
}
