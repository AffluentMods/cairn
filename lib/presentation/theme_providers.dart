// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_providers.dart';
import '../core/theme/cairn_theme.dart';
import '../data/data_providers.dart';

/// Every theme the pickers can choose from: the seven built-ins plus any Theme
/// Designer custom themes (Fix Pass 1 X4.3, X4.4).
final availableThemesProvider = Provider<List<CairnThemeSpec>>((ref) {
  final custom = ref.watch(customThemesProvider).valueOrNull ?? const [];
  return [...cairnBuiltInThemes, ...custom];
});

CairnThemeSpec _resolve(List<CairnThemeSpec> all, String id, bool dark) {
  for (final t in all) {
    if (t.id == id) return t;
  }
  return all.firstWhere((t) => t.isDark == dark, orElse: () => all.first);
}

/// The light and dark [ThemeData] currently selected, rebuilt only when the
/// settings or the available themes change (Fix Pass 1 X4.3).
final activeThemesProvider =
    Provider<({ThemeData light, ThemeData dark})>((ref) {
  final s = ref.watch(settingsProvider);
  final all = ref.watch(availableThemesProvider);
  final dark = _resolve(all, s.darkThemeId, true);
  final light = _resolve(all, s.lightThemeId, false);
  return (light: themeFromSpec(light), dark: themeFromSpec(dark));
});
