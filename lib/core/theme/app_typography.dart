// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Typography (spec Section 9.2). Two families at most: the platform UI font for
/// text, and a monospace with tabular figures for numbers, coordinates, and
/// stats. Nothing below 11 sp.
///
/// We do not bundle font files (keeps the APK small and F-Droid clean); the mono
/// style falls back to the platform monospace, which has tabular digits on
/// Android. If a licensed Inter or JetBrains Mono is added to assets later, set
/// the family names here and nothing else changes.
abstract final class AppTypography {
  static const _monoFallback = <String>['JetBrains Mono', 'monospace'];

  /// Monospace, tabular figures. Use for every number the user reads off (stats,
  /// distances, coordinates, elevations) so digits do not jitter as they change.
  static TextStyle mono(
    TextStyle base, {
    FontWeight weight = FontWeight.w500,
  }) {
    return base.copyWith(
      fontFamilyFallback: _monoFallback,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: weight,
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    final base = (scheme.brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(fontSizeFactor: 1.0);
    // Nothing below 11 sp: labelSmall is the floor.
    return base.copyWith(
      labelSmall: base.labelSmall?.copyWith(fontSize: 11),
    );
  }
}
