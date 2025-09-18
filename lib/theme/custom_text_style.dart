import "package:flutter/material.dart";
import "../theme/app_theme.dart";

/// Typography rules:
///   Headlines/Display: Quattrocento (serif)
///   Body & UI: Inter (or Poppins). We default to Inter.
/// If the font isn't bundled, Flutter will fall back to system fonts.
/// (Optional) To force exact fonts via package: `flutter pub add google_fonts`.
class TextStyleHelper {
  TextStyleHelper._();
  static final TextStyleHelper instance = TextStyleHelper._();

  // ---- Body / UI (Inter) ----
  TextStyle get body12RegularOpenSans => TextStyle(
        // legacy name kept
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.40,
        fontFamily: "Inter",
        color: appTheme.textSecondaryDark,
      );

  TextStyle get body14RegularOpenSans => TextStyle(
        // legacy name kept
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get body14SemiBoldOpenSans => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title16RegularOpenSans => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.38,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title16SemiBoldOpenSans => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.38,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title18MediumInter => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.30,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );

  // Generic button label
  TextStyle get textStyle18 => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.20,
      );

  // ---- Headlines / Display (Quattrocento) ----
  TextStyle get title16BoldQuattrocento => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.30,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title18BoldQuattrocento => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.30,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title20BoldQuattrocento => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.28,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title20RegularRoboto => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 1.30,
        fontFamily: "Roboto",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get headline24BoldQuattrocento => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get headline30BoldQuattrocento => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.20,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get display36BoldQuattrocento => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get label10OpenSans => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.40,
        fontFamily: "OpenSans",
        color: appTheme.textSecondaryDark,
      );

  TextStyle get display48BoldQuattrocento => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.15,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get display60BoldQuattrocento => TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w700,
        height: 1.15,
        fontFamily: "Quattrocento",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title18RegularOpenSans => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.30,
        fontFamily: "OpenSans",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title18SemiBoldOpenSans => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.30,
        fontFamily: "OpenSans",
        color: appTheme.textPrimaryDark,
      );

  TextStyle get title16MediumInter => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.38,
        fontFamily: "Inter",
        color: appTheme.textPrimaryDark,
      );
}
