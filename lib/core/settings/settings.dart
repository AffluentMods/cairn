// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart' show ThemeMode;

import '../units/unit_formatter.dart';

/// The three basemap styles (spec Section 8). Outdoors is the default hero.
enum CairnMapStyle { outdoors, topo, satellite }

/// All user settings, persisted (spec Section 9, Phase 9). Immutable; the
/// notifier writes each change to SharedPreferences.
class Settings {
  const Settings({
    this.mapStyle = CairnMapStyle.outdoors,
    this.units = UnitSystem.imperial,
    this.themeMode = ThemeMode.system,
    this.darkThemeId = 'larch',
    this.lightThemeId = 'paper',
    this.bodyWeightKg,
    this.defaultPackKg,
    this.showConditions = true,
    this.proxyBaseUrl = '',
  });

  final CairnMapStyle mapStyle;
  final UnitSystem units;
  final ThemeMode themeMode;

  /// The theme applied in dark mode and in light mode (Fix Pass 1 X4.3). A
  /// built-in id (larch, paper, ...) or a custom theme's id.
  final String darkThemeId;
  final String lightThemeId;

  final double? bodyWeightKg;
  final double? defaultPackKg;
  final bool showConditions;

  /// Optional Affluent Labs proxy base URL (spec Phase 8). Empty means the app
  /// uses only the no-key sources.
  final String proxyBaseUrl;

  Settings copyWith({
    CairnMapStyle? mapStyle,
    UnitSystem? units,
    ThemeMode? themeMode,
    String? darkThemeId,
    String? lightThemeId,
    double? bodyWeightKg,
    double? defaultPackKg,
    bool? showConditions,
    String? proxyBaseUrl,
  }) {
    return Settings(
      mapStyle: mapStyle ?? this.mapStyle,
      units: units ?? this.units,
      themeMode: themeMode ?? this.themeMode,
      darkThemeId: darkThemeId ?? this.darkThemeId,
      lightThemeId: lightThemeId ?? this.lightThemeId,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      defaultPackKg: defaultPackKg ?? this.defaultPackKg,
      showConditions: showConditions ?? this.showConditions,
      proxyBaseUrl: proxyBaseUrl ?? this.proxyBaseUrl,
    );
  }
}
