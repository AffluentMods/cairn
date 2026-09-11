// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// The Record tab. Phase 6 replaces this with live recording stats.
class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.fiber_manual_record_outlined,
          title: context.l10n.tabRecord,
          message: context.l10n.recordIdle,
        ),
      ),
    );
  }
}
