// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../route_editor_provider.dart';

/// The edit-mode top bar (Addendum A4.3): Undo, Redo, Clear, and a gold Done.
/// Slides in over the map while customizing a route; the sheet holds no gold
/// element while editing so Done owns the accent.
class EditToolbar extends ConsumerWidget {
  const EditToolbar({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canUndo = ref.watch(routeEditorProvider.select((s) => s.canUndo));
    final canRedo = ref.watch(routeEditorProvider.select((s) => s.canRedo));
    final editor = ref.read(routeEditorProvider.notifier);
    return Material(
      color: scheme.surface,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: l10n.planUndo,
                onPressed: canUndo ? editor.undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: l10n.planRedo,
                onPressed: canRedo ? editor.redo : null,
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: l10n.navClear,
                onPressed: editor.clear,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.check),
                label: Text(l10n.navDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
