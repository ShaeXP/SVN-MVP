import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle appTitle(BuildContext context) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.15,
      );

  static TextStyle screenTitle(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle sectionTitle(BuildContext context) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      );

  /// Used for summary-style option rows in bottom sheets.
  /// One point smaller than sectionTitle and slightly lighter weight.
  static TextStyle summaryOption(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodySecondary(BuildContext context) => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
      );

  static TextStyle bottomNavLabelSelected(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle bottomNavLabelUnselected(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
        letterSpacing: 0.1,
      );
}


