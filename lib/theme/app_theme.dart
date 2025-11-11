import "package:flutter/material.dart";

/// Brand colors
///   Deep Purple   #a26dc6
///   Lavender      #ab9ddb
///   Indigo Blue   #6d69bd
///   Teal Blue     #44739f
///   Soft White    #fefefe
/// Extras (UI neutrals / darks):
///   Ink           #0B0B0F (nearly black)
///   Slate-900     #0F172A (deep blue-black)
///   Indigo-900    #312E81
///   Blue-900      #1E3A8A
class AppTheme {
  AppTheme._();
  static final AppTheme instance = AppTheme._();

  // Brand palette
  final Color brandDeepPurple = const Color(0xFFA26DC6);
  final Color brandLavender = const Color(0xFFAB9DDB);
  final Color brandIndigoBlue = const Color(0xFF6D69BD);
  final Color brandTealBlue = const Color(0xFF44739F);
  final Color brandSoftWhite = const Color(0xFFFEFEFE);

  // UI darks / inks
  final Color ink = const Color(0xFF0B0B0F); // near-black
  final Color slate_900 = const Color(0xFF0F172A); // blue-black
  final Color indigo_900 = const Color(0xFF312E81);
  final Color blue_900 = const Color(0xFF1E3A8A);

  // Material-ish grays for borders, dividers, muted text
  final Color gray_50 = const Color(0xFFFAFAFA);
  final Color gray_100 = const Color(0xFFF5F5F5);
  final Color gray_200 = const Color(0xFFEEEEEE);
  final Color gray_300 = const Color(0xFFE0E0E0);
  final Color gray_500 = const Color(0xFF9E9E9E);
  final Color gray_600 = const Color(0xFF757575);
  final Color gray_700 = const Color(0xFF616161);
  final Color gray_900 = const Color(0xFF212121);

  // Legacy names used in code
  final Color white_A700 = const Color(0xFFFFFFFF);
  final Color whiteCustom = const Color(0xFFFFFFFF);
  final Color transparentCustom = Colors.transparent;
  final Color grey100 = const Color(0xFFF5F5F5);
  final Color grey200 = const Color(0xFFEEEEEE);

  // Semantic accents referenced in errors (mapped into your brand)
  final Color red_50 = const Color(0xFFFFEBEE);
  final Color red_100 = const Color(0xFFFFCDD2);
  final Color red_200 = const Color(0xFFEF9A9A);
  final Color red_300 = const Color(0xFFE57373);
  final Color red_400 = const Color(0xFFEF5350);
  final Color red_500 = const Color(0xFFF44336);
  final Color red_600 = const Color(0xFFE53935);
  final Color red_700 = const Color(0xFFD32F2F);
  final Color redCustom = const Color(0xFFE53935);
  
  // Blue variants
  final Color blue_50 = const Color(0xFFE3F2FD);
  final Color blue_200 = const Color(0xFF90CAF9);
  final Color blue_400 = const Color(0xFF42A5F5);
  final Color blue_600 = const Color(0xFF1E88E5);
  
  // Deep purple variants
  final Color deep_purple_50 = const Color(0xFFF3E5F5);
  final Color orange_900 = const Color(0xFFE65100);
  final Color green_600 = const Color(0xFF43A047);
  final Color cyan_900 = const Color(0xFF006064);
  final Color teal_600 = const Color(0xFF00897B);

  // �colorXXXXXXXX� tokens your code referenced (tie to brand where sensible)
  final Color color1F0C17 = const Color(0xFF1F0C17);
  final Color color1F3817 = const Color(0xFF1F3817);
  final Color color281E12 = const Color(0xFF281E12); // dark UI text on light
  final Color color281F1E = const Color(0xFF281F1E);
  final Color color8110B9 = const Color(0xFF8110B9); // deep purple variant
  final Color colorF16366 = const Color(0xFFF16366); // warm accent
  final Color colorF51988 = const Color(0xFFF51988); // magenta CTA
  final Color color16F973 = const Color(0xFF16F973); // success glow
  final Color color44EF44 = const Color(0xFF44EF44); // success brand

  // Brand-mapped accents and neutrals (used throughout the UI)
  final Color blue_200_01 = const Color(0xFF6D69BD); // Indigo Blue
  final Color gray_50_01  = const Color(0xFFFEFEFE); // Soft White (alias)
  final Color gray_900_01 = const Color(0xFF1E1E1E); // near-black for text
  final Color neutral     = const Color(0xFFFEFEFE); // use soft white as neutral
  final Color colorE67FDE = const Color(0xFFE67FDE); // lavender accent

  // Additional colors referenced in UI
  final Color color7FDEE1 = const Color(0xFF7FDEE1); // cyan accent
  final Color cyan_50 = const Color(0xFFE0F7FA);
  final Color cyan_50_01 = const Color(0xFFE0F7FA);
  final Color blue_A700 = const Color(0xFF1976D2);
  final Color orange_50 = const Color(0xFFFFF3E0);
  final Color orange_200 = const Color(0xFFFFCC80);
  final Color orange_600 = const Color(0xFFFB8C00);
  final Color blue_gray_900 = const Color(0xFF263238);

  // Convenience aliases for brand usage in widgets
  Color get primary => brandDeepPurple;
  Color get secondary => brandLavender;
  Color get accentIndigo => brandIndigoBlue;
  Color get accentTeal => brandTealBlue;
  Color get backgroundLight => brandSoftWhite;
  Color get textPrimaryDark => slate_900; // high-contrast text on light bg
  Color get textSecondaryDark => gray_500; // muted text on light bg
  Color get surfaceDark => ink; // dark surfaces (cards in dark mode)
}

// Export singleton (existing code uses: appTheme.xxx)
final appTheme = AppTheme.instance;
