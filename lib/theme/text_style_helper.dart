import 'package:flutter/material.dart';
import '../core/app_export.dart';

/// A helper class for managing text styles in the application
class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  // Display Styles
  // Large text styles typically used for headers and hero elements

  TextStyle get display60BoldQuattrocento => TextStyle(
        fontSize: 60.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get display48BoldQuattrocento => TextStyle(
        fontSize: 48.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get display36BoldQuattrocento => TextStyle(
        fontSize: 36.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  // Headline Styles
  // Medium-large text styles for section headers

  TextStyle get headline30BoldQuattrocento => TextStyle(
        fontSize: 30.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get headline24BoldQuattrocento => TextStyle(
        fontSize: 24.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  // Title Styles
  // Medium text styles for titles and subtitles

  TextStyle get title20BoldQuattrocento => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get title20RegularRoboto => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      );

  TextStyle get title18BoldQuattrocento => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get title18RegularOpenSans => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Open Sans',
        color: appTheme.gray_700,
      );

  TextStyle get title18MediumInter => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
        color: appTheme.gray_900,
      );

  TextStyle get title16RegularOpenSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Open Sans',
        color: appTheme.gray_700,
      );

  TextStyle get title18SemiBoldOpenSans => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Open Sans',
        color: appTheme.cyan_900,
      );

  TextStyle get title16MediumInter => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
        color: appTheme.gray_900,
      );

  TextStyle get title16BoldQuattrocento => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Quattrocento',
        color: appTheme.gray_900,
      );

  TextStyle get title16SemiBoldOpenSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Open Sans',
        color: appTheme.gray_900,
      );

  // Body Styles
  // Standard text styles for body content

  TextStyle get body14RegularOpenSans => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Open Sans',
      );

  TextStyle get body14SemiBoldOpenSans => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Open Sans',
        color: appTheme.gray_700,
      );

  TextStyle get body12RegularOpenSans => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Open Sans',
      );

  // Label Styles
  // Small text styles for labels, captions, and hints

  TextStyle get label10OpenSans => TextStyle(
        fontSize: 10.fSize,
        fontFamily: 'Open Sans',
      );

  // Other Styles
  // Miscellaneous text styles without specified font size

  TextStyle get textStyle18 => TextStyle();
}
