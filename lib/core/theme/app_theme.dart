// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Dark and light themes (spec Section 9). Dark is the hero: this app gets used
/// at 4 AM in a car and at camp at dusk. One gold accent per surface, everything
/// else outline or text. Nothing glows, nothing bounces for no reason.
abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.larch,
      brightness: Brightness.dark,
      surface: AppColors.ink,
    ).copyWith(
      primary: AppColors.larch,
      secondary: AppColors.glacier,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      surfaceContainerHighest: AppColors.inkRaised,
    );
    return _base(
      scheme,
      scaffold: AppColors.inkDeep,
      indicator: AppColors.larch.withValues(alpha: 0.18),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.larchLight,
      brightness: Brightness.light,
      surface: AppColors.paperRaised,
    ).copyWith(
      primary: AppColors.larchLight,
      secondary: AppColors.trackLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      surfaceContainerHighest: AppColors.paper,
    );
    return _base(
      scheme,
      scaffold: AppColors.paper,
      indicator: AppColors.larchLight.withValues(alpha: 0.16),
    );
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required Color scaffold,
    required Color indicator,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: AppTypography.textTheme(scheme),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: indicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: scheme.surface,
      ),
      cardTheme: const CardThemeData(elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
