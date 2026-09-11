// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../shared/empty_state.dart';

/// Offline regions manager. Phase 5 fills this in.
class OfflineRegionsScreen extends ConsumerWidget {
  const OfflineRegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.offlineTitle)),
      body: EmptyState(
        icon: Icons.download_for_offline_outlined,
        title: context.l10n.offlineTitle,
        message: context.l10n.libraryEmptyOffline,
      ),
    );
  }
}
