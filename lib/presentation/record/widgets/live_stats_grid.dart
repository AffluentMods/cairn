// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/units/unit_formatter.dart';
import '../../shared/stat_tile.dart';
import '../recording_provider.dart';

/// The live stats grid while recording (spec Section 9.6): distance, moving
/// time, pace, gain, speed, elevation.
class LiveStatsGrid extends ConsumerWidget {
  const LiveStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final stats = ref.watch(recordingProvider.select((s) => s.stats));

    final tiles = <Widget>[
      StatTile(
        value: fmt.distance(stats.distanceM),
        label: l10n.statDistance,
        emphasized: true,
      ),
      StatTile(
        value: UnitFormatter.durationClock(
          Duration(seconds: stats.movingSeconds),
        ),
        label: l10n.statMoving,
      ),
      StatTile(value: fmt.pace(stats.currentSpeedMps), label: l10n.statPace),
      StatTile(value: fmt.elevationSigned(stats.gainM), label: l10n.statGain),
      StatTile(value: fmt.speed(stats.currentSpeedMps), label: l10n.statSpeed),
      StatTile(
        value: stats.currentElevM == null
            ? '--'
            : fmt.elevation(stats.currentElevM!),
        label: l10n.statElevation,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: tiles,
    );
  }
}
