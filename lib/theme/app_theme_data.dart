import "package:flutter/material.dart";
import "app_theme.dart";
import "custom_text_style.dart";

class AppThemeData {
  AppThemeData._();

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: appTheme.brandDeepPurple,
      brightness: Brightness.light,
      primary: appTheme.brandDeepPurple,
      secondary: appTheme.brandLavender,
      background: appTheme.brandSoftWhite,
      surface: appTheme.brandSoftWhite,
    );
    final helper = TextStyleHelper.instance;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: appTheme.backgroundLight,
      textTheme: TextTheme(
        bodySmall: helper.body12RegularOpenSans,
        bodyMedium: helper.body14RegularOpenSans,
        bodyLarge: helper.title16RegularOpenSans,
        titleSmall: helper.title16SemiBoldOpenSans,
        titleMedium: helper.title18MediumInter,
        titleLarge: helper.title20BoldQuattrocento,
        headlineSmall: helper.headline24BoldQuattrocento,
        headlineMedium: helper.headline30BoldQuattrocento,
        displaySmall: helper.display36BoldQuattrocento,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: appTheme.textPrimaryDark,
        titleTextStyle: helper.title18BoldQuattrocento,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: appTheme.indigo_900),
      dividerTheme: DividerThemeData(color: appTheme.gray_200, thickness: 1),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: cs.primary,
          textStyle: helper.textStyle18,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appTheme.brandIndigoBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appTheme.gray_100,
        hintStyle:
            helper.body14RegularOpenSans.copyWith(color: appTheme.gray_500),
        labelStyle: helper.body14RegularOpenSans,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appTheme.gray_300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appTheme.red_400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appTheme.red_700, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: appTheme.gray_100,
        selectedColor: cs.secondaryContainer,
        disabledColor: appTheme.gray_200,
        labelStyle: helper.body12RegularOpenSans,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: cs.primary,
        unselectedItemColor: appTheme.gray_500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: helper.body12RegularOpenSans,
        unselectedLabelStyle: helper.body12RegularOpenSans,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return helper.body12RegularOpenSans.copyWith(color: cs.primary);
          }
          return helper.body12RegularOpenSans.copyWith(color: appTheme.gray_500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: appTheme.gray_500);
        }),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: appTheme.brandDeepPurple,
      brightness: Brightness.dark,
      primary: appTheme.brandDeepPurple,
      secondary: appTheme.brandLavender,
      background: appTheme.slate_900,
      surface: appTheme.slate_900,
    );
    final helper = TextStyleHelper.instance;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: appTheme.slate_900,
      textTheme: TextTheme(
        bodySmall: helper.body12RegularOpenSans.copyWith(color: Colors.white70),
        bodyMedium: helper.body14RegularOpenSans.copyWith(color: Colors.white),
        bodyLarge: helper.title16RegularOpenSans.copyWith(color: Colors.white),
        titleSmall:
            helper.title16SemiBoldOpenSans.copyWith(color: Colors.white),
        titleMedium: helper.title18MediumInter.copyWith(color: Colors.white),
        titleLarge:
            helper.title20BoldQuattrocento.copyWith(color: Colors.white),
        headlineSmall:
            helper.headline24BoldQuattrocento.copyWith(color: Colors.white),
        headlineMedium:
            helper.headline30BoldQuattrocento.copyWith(color: Colors.white),
        displaySmall:
            helper.display36BoldQuattrocento.copyWith(color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: Colors.white,
        titleTextStyle:
            helper.title18BoldQuattrocento.copyWith(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      dividerTheme: DividerThemeData(color: Colors.white10, thickness: 1),
      cardTheme: CardThemeData(
        color: const Color(0xFF15151B),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: cs.primary,
          textStyle: helper.textStyle18,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121219),
        hintStyle: helper.body14RegularOpenSans.copyWith(color: Colors.white54),
        labelStyle: helper.body14RegularOpenSans.copyWith(color: Colors.white),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appTheme.red_400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appTheme.red_700, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E2230),
        selectedColor: cs.secondaryContainer,
        disabledColor: const Color(0xFF272B3A),
        labelStyle: helper.body12RegularOpenSans.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF121219),
        selectedItemColor: cs.primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            helper.body12RegularOpenSans.copyWith(color: Colors.white),
        unselectedLabelStyle:
            helper.body12RegularOpenSans.copyWith(color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF121219),
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return helper.body12RegularOpenSans.copyWith(color: cs.primary);
          }
          return helper.body12RegularOpenSans.copyWith(color: Colors.white54);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: Colors.white54);
        }),
      ),
    );
  }
}
