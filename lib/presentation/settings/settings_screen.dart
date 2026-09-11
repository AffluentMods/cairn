// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// Settings. Phase 9 fills this in (units, theme, default style, weights, cache,
/// sources, privacy, licenses, version). Phase 0 is a placeholder.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: EmptyState(
        icon: Icons.tune_outlined,
        title: context.l10n.settingsTitle,
        message: context.l10n.phase0Placeholder,
      ),
    );
  }
}
