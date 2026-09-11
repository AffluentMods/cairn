// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/cairn_theme.dart';
import '../../core/theme/theme_providers.dart';
import 'settings_screen.dart' show RadioListTileless;
import 'widgets/theme_preview_card.dart';

/// Settings > Appearance (Fix Pass 1 X4.3): pick the mode (System/Dark/Light)
/// and the theme used in each mode, from live preview cards.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final all = ref.watch(availableThemesProvider);
    final dark = [for (final t in all) if (t.isDark) t];
    final light = [for (final t in all) if (!t.isDark) t];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearanceTitle)),
      body: ListView(
        children: [
          _header(context, l10n.appearanceModeHeader),
          for (final mode in ThemeMode.values)
            RadioListTileless(
              selected: s.themeMode == mode,
              title: switch (mode) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.dark => l10n.themeDark,
                ThemeMode.light => l10n.themeLight,
              },
              onTap: () => notifier.setThemeMode(mode),
            ),
          const Divider(),
          _header(context, l10n.appearanceDarkTheme),
          _grid(dark, s.darkThemeId, notifier.setDarkThemeId),
          const SizedBox(height: 8),
          _header(context, l10n.appearanceLightTheme),
          _grid(light, s.lightThemeId, notifier.setLightThemeId),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _grid(
    List<CairnThemeSpec> specs,
    String selectedId,
    void Function(String) onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final spec in specs)
            ThemePreviewCard(
              spec: spec,
              selected: spec.id == selectedId,
              onTap: () => onPick(spec.id),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
