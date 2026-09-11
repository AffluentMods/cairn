// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_ext.dart';

/// The 4-tab bottom navigation shell: Map, Plan, Record, Library (spec Section 3).
/// Settings lives behind the Library tab, not a fifth tab.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    // Tapping the active tab pops it to its root, matching platform convention.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.tabMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: l10n.tabPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radio_button_checked_outlined),
            selectedIcon: const Icon(Icons.radio_button_checked),
            label: l10n.tabRecord,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.tabLibrary,
          ),
        ],
      ),
    );
  }
}
