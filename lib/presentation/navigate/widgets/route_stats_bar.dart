// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/units/unit_formatter.dart';
import '../../shared/stat_tile.dart';
import '../route_editor_provider.dart';

/// The stats strip for the plan: distance, gain, loss, high point, and an
/// estimated time (spec Section 9.6). No overclaimed precision.
class RouteStatsBar extends ConsumerWidget {
  const RouteStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(routeEditorProvider);
    final stats = state.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: fmt.distance(stats.distanceM),
                label: l10n.statDistance,
                emphasized: true,
              ),
            ),
            Expanded(
              child: StatTile(
                value: fmt.elevationSigned(stats.gainM),
                label: l10n.statGain,
              ),
            ),
            Expanded(
              child: StatTile(
                value: fmt.elevationSigned(-stats.lossM),
                label: l10n.statLoss,
              ),
            ),
            Expanded(
              child: StatTile(
                value: fmt.elevation(stats.maxElevM),
                label: l10n.statHighPoint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (stats.estimatedTime > Duration.zero)
              Text(
                l10n.planEstTime(UnitFormatter.durationHm(stats.estimatedTime)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const Spacer(),
            if (state.computing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (state.hasOffTrailLeg && !state.computing)
              _OffTrailChip(label: l10n.planOffTrail),
          ],
        ),
      ],
    );
  }
}

class _OffTrailChip extends StatelessWidget {
  const _OffTrailChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
