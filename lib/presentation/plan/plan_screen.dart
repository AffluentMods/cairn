// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// The Plan tab. Phase 3 replaces this with the route editor.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.planTitle)),
      body: EmptyState(
        icon: Icons.route_outlined,
        title: context.l10n.planTitle,
        message: context.l10n.phase0Placeholder,
      ),
    );
  }
}
