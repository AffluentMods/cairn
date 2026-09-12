// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart' show ThemeMode;

import '../../domain/usecases/recording_engine.dart' show RecordingProfile;
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
    this.recordingProfile = RecordingProfile.precise,
    this.autoPause = true,
    this.autoSaver = true,
    this.keepScreenOn = false,
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

  /// Recording (spec Phase 6): GPS power profile, auto-pause when stationary,
  /// automatic Saver profile on a low battery, keep the screen on while the
  /// recording view is up.
  final RecordingProfile recordingProfile;
  final bool autoPause;
  final bool autoSaver;
  final bool keepScreenOn;

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
    RecordingProfile? recordingProfile,
    bool? autoPause,
    bool? autoSaver,
    bool? keepScreenOn,
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
      recordingProfile: recordingProfile ?? this.recordingProfile,
      autoPause: autoPause ?? this.autoPause,
      autoSaver: autoSaver ?? this.autoSaver,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }
}
