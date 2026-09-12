// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../units/unit_formatter.dart';
import 'settings.dart';

/// Overridden in main() with the loaded instance. SharedPreferences holds only
/// non-sensitive settings (spec Section 4).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

const _kMapStyle = 'settings.mapStyle';
const _kUnits = 'settings.units';
const _kThemeMode = 'settings.themeMode';
const _kDarkTheme = 'settings.darkThemeId';
const _kLightTheme = 'settings.lightThemeId';
const _kBodyWeight = 'settings.bodyWeightKg';
const _kPackWeight = 'settings.defaultPackKg';
const _kShowConditions = 'settings.showConditions';
const _kProxyBaseUrl = 'settings.proxyBaseUrl';

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return Settings(
      mapStyle: _enumByName(
        CairnMapStyle.values,
        prefs.getString(_kMapStyle),
        CairnMapStyle.outdoors,
      ),
      units: _enumByName(
        UnitSystem.values,
        prefs.getString(_kUnits),
        UnitSystem.imperial,
      ),
      themeMode: _enumByName(
        ThemeMode.values,
        prefs.getString(_kThemeMode),
        ThemeMode.system,
      ),
      darkThemeId: prefs.getString(_kDarkTheme) ?? 'larch',
      lightThemeId: prefs.getString(_kLightTheme) ?? 'paper',
      bodyWeightKg: prefs.getDouble(_kBodyWeight),
      defaultPackKg: prefs.getDouble(_kPackWeight),
      showConditions: prefs.getBool(_kShowConditions) ?? true,
      proxyBaseUrl: prefs.getString(_kProxyBaseUrl) ?? '',
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> setMapStyle(CairnMapStyle style) async {
    state = state.copyWith(mapStyle: style);
    await _prefs.setString(_kMapStyle, style.name);
  }

  Future<void> setUnits(UnitSystem units) async {
    state = state.copyWith(units: units);
    await _prefs.setString(_kUnits, units.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setDarkThemeId(String id) async {
    state = state.copyWith(darkThemeId: id);
    await _prefs.setString(_kDarkTheme, id);
  }

  Future<void> setLightThemeId(String id) async {
    state = state.copyWith(lightThemeId: id);
    await _prefs.setString(_kLightTheme, id);
  }

  Future<void> setBodyWeightKg(double? kg) async {
    state = state.copyWith(bodyWeightKg: kg);
    if (kg == null) {
      await _prefs.remove(_kBodyWeight);
    } else {
      await _prefs.setDouble(_kBodyWeight, kg);
    }
  }

  Future<void> setDefaultPackKg(double? kg) async {
    state = state.copyWith(defaultPackKg: kg);
    if (kg == null) {
      await _prefs.remove(_kPackWeight);
    } else {
      await _prefs.setDouble(_kPackWeight, kg);
    }
  }

  Future<void> setShowConditions(bool show) async {
    state = state.copyWith(showConditions: show);
    await _prefs.setBool(_kShowConditions, show);
  }

  /// Returns false and leaves the setting unchanged when [url] is not an
  /// `https://` address (empty disables the proxy). Coordinates are sent to this
  /// host, so a cleartext or malformed value is refused instead of failing
  /// silently under the network security config (security re-audit, finding 7).
  Future<bool> setProxyBaseUrl(String url) async {
    final normalized = normalizeProxyUrl(url);
    if (normalized == null) return false;
    state = state.copyWith(proxyBaseUrl: normalized);
    await _prefs.setString(_kProxyBaseUrl, normalized);
    return true;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

/// The formatter for the current unit system.
final unitFormatterProvider = Provider<UnitFormatter>(
  (ref) => UnitFormatter(ref.watch(settingsProvider.select((s) => s.units))),
);

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Normalizes a user-typed proxy base URL: trimmed, `https://` with a host,
/// trailing slashes removed. Returns an empty string for an empty input (proxy
/// off) and null for anything that is not a valid https address.
String? normalizeProxyUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final uri = Uri.tryParse(t);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  var s = t;
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
