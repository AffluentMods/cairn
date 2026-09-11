// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/cairn_theme.dart';
import '../../core/theme/theme_codec.dart';
import '../../data/data_providers.dart';
import '../theme_providers.dart';
import 'settings_screen.dart' show RadioListTileless;
import 'theme_designer_screen.dart';
import 'widgets/theme_preview_card.dart';

/// Settings > Appearance (Fix Pass 1 X4.3, X4.4): pick the mode and the theme
/// for each mode from live preview cards, and create, edit, or import custom
/// themes.
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
      appBar: AppBar(
        title: Text(l10n.appearanceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.designerImport,
            onPressed: () => _import(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.appearanceCreate,
            onPressed: () => _create(context),
          ),
        ],
      ),
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
          _grid(context, dark, s.darkThemeId, notifier.setDarkThemeId),
          const SizedBox(height: 8),
          _header(context, l10n.appearanceLightTheme),
          _grid(context, light, s.lightThemeId, notifier.setLightThemeId),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _grid(
    BuildContext context,
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
              // A custom theme (not a built-in) can be edited by long-press.
              onLongPress: builtInThemeById(spec.id) == null
                  ? () => _edit(context, spec)
                  : null,
            ),
        ],
      ),
    );
  }

  void _create(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThemeDesignerScreen(base: cairnBuiltInThemes.first),
      ),
    );
  }

  void _edit(BuildContext context, CairnThemeSpec spec) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ThemeDesignerScreen(base: spec, isEditingCustom: true),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.designerImport),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.designerImportHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.designerImport),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      final id = 'custom-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      final spec = themeFromImport(text, id: id);
      await ref.read(customThemeRepositoryProvider).save(spec);
      messenger.showSnackBar(SnackBar(content: Text(l10n.designerImported)));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.designerImportFailed)));
    }
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
