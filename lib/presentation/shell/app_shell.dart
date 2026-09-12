// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/theme/cairn_colors.dart';
import 'shell_providers.dart';

/// The four-tab bottom navigation shell: Explore, Navigate, Saved, Activity
/// (Addendum A1). Settings lives behind the Saved app bar, not a fifth tab.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    // Tapping the active tab pops it to its root, matching platform convention.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = shell.currentIndex;
    // Keep shellIndexProvider in sync so CairnMap only mounts the active tab
    // (Addendum A3: one MapLibre surface at a time).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (ref.read(shellIndexProvider) != current) {
        ref.read(shellIndexProvider.notifier).state = current;
      }
    });
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        // Nav bar sits on the background with a hairline top border, not a
        // floating tinted surface (Fix Pass 1 X4.5).
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cairn.outline)),
        ),
        child: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: _onTap,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: l10n.tabExplore,
            ),
            NavigationDestination(
              icon: const Icon(Icons.navigation_outlined),
              selectedIcon: const Icon(Icons.navigation),
              label: l10n.tabNavigate,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_border),
              selectedIcon: const Icon(Icons.bookmark),
              label: l10n.tabSaved,
            ),
            NavigationDestination(
              icon: const Icon(Icons.timeline),
              selectedIcon: const Icon(Icons.timeline),
              label: l10n.tabActivity,
            ),
          ],
        ),
      ),
    );
  }
}
