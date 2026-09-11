// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// The Map tab. Phase 1 replaces this placeholder with the MapLibre map.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.map_outlined,
          title: context.l10n.tabMap,
          message: context.l10n.phase0Placeholder,
        ),
      ),
    );
  }
}
