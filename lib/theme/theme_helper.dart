import 'package:flutter/material.dart';

/// Public getters kept for compatibility with the rest of the app.
LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.
// ignore_for_file: must_be_immutable
class ThemeHelper {
  // Current app theme key (Rocket expects this shape)
  var _appTheme = "lightCode";

  // Supported custom color buckets (leave as-is so other code compiles)
  final Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors(),
  };

  // Supported color schemes
  final Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme,
  };

  /// Returns the custom colors for the current theme.
  LightCodeColors _getThemeColors() =>
      _supportedCustomColor[_appTheme] ?? LightCodeColors();

  /// Builds ThemeData for the current theme.
  ThemeData _getThemeData() {
    final scheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;

    // Global text styles — HEADINGS use the darkest navy (no lavender)
    const headingColor = Color(0xFF17366E); // deepest brand blue
    const bodyColor = Color(0xFF0F172A); // slate-900-like
    const bodyMuted = Color(0xFF64748B); // slate-500-like

    final textTheme = const TextTheme(
      // Display = large headings
      displayLarge: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: headingColor,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.18,
        color: headingColor,
      ),
      // TitleLarge ~ section headers
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: bodyColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: bodyMuted,
      ),
      // Labels (buttons, chips)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F9FC), // light cloud bg
      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: bodyColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: bodyColor,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF8EC2FF); // primary300
            }
            return const Color(0xFF3B8CFF); // primary500
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          foregroundColor: WidgetStateProperty.all(bodyColor),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF2F6FE0)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: bodyMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF5FA5FF), width: 1.2),
        ),
      ),

      // Cards/Dialogs
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        shadowColor: const Color(0x1A0F172A),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x0F0F172A),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: bodyColor,
        ),
        selectedColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 10, offset: Offset(0, 2))],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        labelColor: bodyColor,
        unselectedLabelColor: bodyMuted,
        dividerColor: Colors.transparent,
      ),

      dividerColor: const Color(0xFFE2E8F0),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Color(0xFF3B8CFF)),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: TextStyle(color: bodyColor),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: Colors.white),
        textStyle: TextStyle(color: bodyColor),
      ),
    );
  }

  /// Public API used by the rest of the app
  LightCodeColors themeColor() => _getThemeColors();
  ThemeData themeData() => _getThemeData();
}

/// Color scheme used by ThemeData — updated to deep blue brand.
class ColorSchemes {
  static final lightCodeColorScheme = const ColorScheme.light().copyWith(
    primary: const Color(0xFF3B8CFF), // primary500
    onPrimary: Colors.white,
    secondary: const Color(0xFF6EE7F5), // accent aqua
    onSecondary: Colors.black,
    surface: Colors.white,
    onSurface: const Color(0xFF0F172A),
    error: const Color(0xFFEF4444),
    onError: Colors.white,
  );
}

/// Legacy color bucket Rocket generated. We keep it so other code importing
/// `appTheme` doesn’t break. You can ignore the old lavender fields now.
class LightCodeColors {
  // Existing Rocket scaffolded colors (left intact for compatibility)
  Color get gray_900 => const Color(0xFF171A1F);
  Color get gray_300 => const Color(0xFFDEE1E6);
  Color get white_A700 => const Color(0xFFFFFFFF);
  Color get gray_700 => const Color(0xFF565D6D);
  Color get blue_200 => const Color(0xFF8ACAF5);
  Color get cyan_900 => const Color(0xFF0A4D79);
  Color get blue_200_01 => const Color(0xFF88CAF5);
  Color get red_400 => const Color(0xFFCA5551);
  Color get gray_200 => const Color(0xFFE5E7EB);
  Color get gray_900_1e => const Color(0x1E120F28);
  Color get blue_A200 => const Color(0xFF5A8EE4);
  Color get gray_50 => const Color(0xFFFAFAFB);
  Color get gray_900_01 => const Color(0xFF19191F);
  Color get gray_50_01 => const Color(0xFFF1F9FE);
  Color get gray_100 => const Color(0xFFF3F4F6);
  Color get cyan_50 => const Color(0xFFE7F9F3);
  Color get blue_gray_900 => const Color(0xFF323742);
  Color get teal_400_19 => const Color(0x1910B981);
  Color get teal_600 => const Color(0xFF059669);
  Color get gray_900_02 => const Color(0xFF1F1E28);
  Color get indigo_A200_19 => const Color(0x196366F1);
  Color get indigo_A400 => const Color(0xFF4F46E5);
  Color get deep_purple_A200_19 => const Color(0x19A855F7);
  Color get deep_purple_A200 => const Color(0xFF9333EA);
  Color get blue_A200_19 => const Color(0x193B82F6);
  Color get blue_A700 => const Color(0xFF2563EB);
  Color get yellow_900_19 => const Color(0x19F97316);
  Color get orange_900 => const Color(0xFFEA580C);
  Color get red_500_19 => const Color(0x19EF4444);
  Color get red_700 => const Color(0xFFDC2626);
  Color get gray_500 => const Color(0xFF9095A0);
  Color get cyan_50_01 => const Color(0xFFE5F7FA);
  Color get green_600 => const Color(0xFF57914B);
  Color get deep_purple_50 => const Color(0xFFEFE0FF);

  // Old brand palette (kept, but ThemeData no longer uses these for headings)
  Color get deepPurple => const Color(0xFFA26DC6);
  Color get lavenderPurple => const Color(0xFFAB9DDB);
  Color get indigoBlue => const Color(0xFF6D69BD);
  Color get tealBlue => const Color(0xFF44739F);
  Color get softWhite => const Color(0xFFFEFEFE);

  // Semantic aliases (unused by ThemeData but kept for compatibility)
  Color get primary => deepPurple;
  Color get secondary => lavenderPurple;
  Color get accentIndigo => indigoBlue;
  Color get accentTeal => tealBlue;
  Color get neutral => softWhite;

  // Misc passthroughs
  Color get transparentCustom => Colors.transparent;
  Color get greenCustom => Colors.green;
  Color get whiteCustom => Colors.white;
  Color get redCustom => Colors.red;
  Color get blueCustom => Colors.blue;
  Color get greyCustom => Colors.grey;
  Color get color281E12 => const Color(0x281E120F);
  Color get colorE67FDE => const Color(0xE67FDEE1);
  Color get color1F0C17 => const Color(0x1F0C171A);
  Color get color51B5CA => const Color(0x51B5CA55);
  Color get color7FDEE1 => const Color(0x7FDEE1E6);
  Color get colorF51988 => const Color(0xF51988CA);
  Color get color8110B9 => const Color(0x8110B981);
  Color get color281F1E => const Color(0x281F1E28);
  Color get colorF16366 => const Color(0xF16366F1);
  Color get color16F973 => const Color(0x16F97316);
  Color get color44EF44 => const Color(0x44EF4444);
  Color get colorF7A855 => const Color(0xF7A855F7);
  Color get colorF63B82 => const Color(0xF63B82F6);
  Color get color1F3817 => const Color(0x1F38171A);
  Color get colorFF1988 => const Color(0xFF1988CA);

  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}