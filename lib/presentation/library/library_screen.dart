// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// The Library tab: saved routes, recorded tracks, and offline regions. Settings
/// is reached from this app bar, not a fifth tab (spec Section 3). Phase 4 fills
/// in the three tabs; this is the Phase 0 shell.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabLibrary),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/library/settings'),
          ),
        ],
      ),
      body: EmptyState(
        icon: Icons.folder_outlined,
        title: l10n.tabLibrary,
        message: l10n.phase0Placeholder,
      ),
    );
  }
}
