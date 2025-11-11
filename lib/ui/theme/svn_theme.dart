// lib/ui/theme/svn_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SVNTheme {
  // Brand palette
  static const Color primary = Color(0xFF7C3AED); // purple-600
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color surface = Color(0xFFF7F5FB); // soft lavender/grey
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE9E6F4);
  static const Color text = Color(0xFF0F172A); // slate-900
  static const Color textMuted = Color(0xFF475569);

  // Status colors
  static const Color ok = Color(0xFF10B981); // green-500
  static const Color warn = Color(0xFFF59E0B); // amber-500
  static const Color info = Color(0xFF6366F1); // indigo-500
  static const Color error = Color(0xFFEF4444); // rose-500
  static const Color neutral = Color(0xFF94A3B8); // slate-400

  static const double radius = 22;
  static const double cardPad = 16;

  static ThemeData theme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        secondary: info,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: surface,
    );

    final display = _tryHeadings(base);
    final body = _tryBody(base);

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: display.headlineLarge,
        displayMedium: display.headlineMedium,
        titleLarge: display.titleLarge,
        titleMedium: display.titleMedium,
        bodyLarge: body.bodyLarge,
        bodyMedium: body.bodyMedium,
        bodySmall: body.bodySmall,
        labelLarge: body.labelLarge,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: text,
        titleTextStyle: display.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: primary.withOpacity(0.1),
        disabledColor: neutral.withOpacity(0.1),
        labelStyle: body.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        side: BorderSide(color: border),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: surfaceAlt,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: body.bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: display.titleMedium,
        contentTextStyle: body.bodyMedium,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withOpacity(0.2),
        circularTrackColor: primary.withOpacity(0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  static TextTheme _tryHeadings(ThemeData base) {
    try {
      return GoogleFonts.quattrocentoTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.quattrocento(
          fontSize: 22, fontWeight: FontWeight.w700, color: text,
        ),
        titleMedium: GoogleFonts.quattrocento(
          fontSize: 18, fontWeight: FontWeight.w700, color: text,
        ),
      );
    } catch (_) {
      return base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: text),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: text),
      );
    }
  }

  static TextTheme _tryBody(ThemeData base) {
    try {
      final t = GoogleFonts.poppinsTextTheme(base.textTheme);
      return t.copyWith(
        bodyLarge: t.bodyLarge?.copyWith(color: text),
        bodyMedium: t.bodyMedium?.copyWith(color: textMuted),
        bodySmall: t.bodySmall?.copyWith(color: textMuted),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );
    } catch (_) {
      return base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: text),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: textMuted),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );
    }
  }
}

