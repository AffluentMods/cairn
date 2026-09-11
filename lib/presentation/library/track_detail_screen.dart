// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// Detail for a saved route or recorded track. Phase 4 fills this in.
class TrackDetailScreen extends ConsumerWidget {
  const TrackDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabLibrary)),
      body: EmptyState(
        icon: Icons.timeline_outlined,
        title: id,
        message: context.l10n.phase0Placeholder,
      ),
    );
  }
}
