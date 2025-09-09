import 'package:flutter/material.dart';

LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // The current app theme
  var _appTheme = "lightCode";

  // A map of custom color themes supported by the app
  Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors()
  };

  // A map of color schemes supported by the app
  Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme
  };

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light();
}

class LightCodeColors {
  // App Colors
  Color get gray_900 => Color(0xFF171A1F);
  Color get gray_300 => Color(0xFFDEE1E6);
  Color get white_A700 => Color(0xFFFFFFFF);
  Color get gray_700 => Color(0xFF565D6D);
  Color get blue_200 => Color(0xFF8ACAF5);
  Color get cyan_900 => Color(0xFF0A4D79);
  Color get blue_200_01 => Color(0xFF88CAF5);
  Color get red_400 => Color(0xFFCA5551);
  Color get gray_200 => Color(0xFFE5E7EB);
  Color get gray_900_1e => Color(0x1E120F28);
  Color get blue_A200 => Color(0xFF5A8EE4);
  Color get gray_50 => Color(0xFFFAFAFB);
  Color get gray_900_01 => Color(0xFF19191F);
  Color get gray_50_01 => Color(0xFFF1F9FE);
  Color get gray_100 => Color(0xFFF3F4F6);
  Color get cyan_50 => Color(0xFFE7F9F3);
  Color get blue_gray_900 => Color(0xFF323742);
  Color get teal_400_19 => Color(0x1910B981);
  Color get teal_600 => Color(0xFF059669);
  Color get gray_900_02 => Color(0xFF1F1E28);
  Color get indigo_A200_19 => Color(0x196366F1);
  Color get indigo_A400 => Color(0xFF4F46E5);
  Color get deep_purple_A200_19 => Color(0x19A855F7);
  Color get deep_purple_A200 => Color(0xFF9333EA);
  Color get blue_A200_19 => Color(0x193B82F6);
  Color get blue_A700 => Color(0xFF2563EB);
  Color get yellow_900_19 => Color(0x19F97316);
  Color get orange_900 => Color(0xFFEA580C);
  Color get red_500_19 => Color(0x19EF4444);
  Color get red_700 => Color(0xFFDC2626);
  Color get gray_500 => Color(0xFF9095A0);
  Color get cyan_50_01 => Color(0xFFE5F7FA);
  Color get green_600 => Color(0xFF57914B);
  Color get deep_purple_50 => Color(0xFFEFE0FF);

  // Additional Colors
  Color get transparentCustom => Colors.transparent;
  Color get greenCustom => Colors.green;
  Color get whiteCustom => Colors.white;
  Color get redCustom => Colors.red;
  Color get blueCustom => Colors.blue;
  Color get greyCustom => Colors.grey;
  Color get color281E12 => Color(0x281E120F);
  Color get colorE67FDE => Color(0xE67FDEE1);
  Color get color1F0C17 => Color(0x1F0C171A);
  Color get color51B5CA => Color(0x51B5CA55);
  Color get color7FDEE1 => Color(0x7FDEE1E6);
  Color get colorF51988 => Color(0xF51988CA);
  Color get color8110B9 => Color(0x8110B981);
  Color get color281F1E => Color(0x281F1E28);
  Color get colorF16366 => Color(0xF16366F1);
  Color get color16F973 => Color(0x16F97316);
  Color get color44EF44 => Color(0x44EF4444);
  Color get colorF7A855 => Color(0xF7A855F7);
  Color get colorF63B82 => Color(0xF63B82F6);
  Color get color1F3817 => Color(0x1F38171A);
  Color get colorFF1988 => Color(0xFF1988CA);

  // Color Shades - Each shade has its own dedicated constant
  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}
