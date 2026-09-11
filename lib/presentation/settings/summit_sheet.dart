// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../data/purchases/purchases.dart';

/// The Cairn Summit unlock sheet (spec Section 12.4). Shown only in the store
/// build when a Summit feature is gated; community and self-compiled builds
/// never reach it (everything is unlocked). Safety features are never gated.
Future<void> showSummit(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SummitSheet(),
  );
}

class _SummitSheet extends ConsumerStatefulWidget {
  const _SummitSheet();

  @override
  ConsumerState<_SummitSheet> createState() => _SummitSheetState();
}

class _SummitSheetState extends ConsumerState<_SummitSheet> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function(PurchaseGateway g) action) async {
    setState(() => _busy = true);
    try {
      final owned = await action(ref.read(purchaseGatewayProvider));
      ref.invalidate(summitEntitlementProvider);
      if (owned && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.summitTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.summitOneTime,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            for (final f in [
              l10n.summitFeatureOffline,
              l10n.summitFeatureWater,
              l10n.summitFeatureFollow,
              l10n.summitFeatureAirnow,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : () => _run((g) => g.buySummit()),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.summitBuy('\$9.99')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run((g) async {
                          await g.restore();
                          return g.hasSummit();
                        }),
                child: Text(l10n.summitRestore),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
