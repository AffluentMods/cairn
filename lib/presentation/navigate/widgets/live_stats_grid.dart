// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/units/unit_formatter.dart';
import '../../shared/stat_tile.dart';
import '../recording_provider.dart';

/// The three numbers that stay visible in the collapsed recording sheet
/// (spec Section 9.6, mobile track: the map is the hero): distance, active
/// time (advanced locally between service reports so the clock never
/// stutters), and distance to go on a route or moving time otherwise.
class RecordingPrimaryRow extends ConsumerWidget {
  const RecordingPrimaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(recordingProvider);
    final stats = state.stats;
    final following = state.routeLengthM != null;
    final remaining = state.distanceRemainingM;

    return Row(
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
            value: UnitFormatter.durationClock(
              Duration(seconds: state.totalSecondsNow),
            ),
            label: l10n.statActive,
          ),
        ),
        Expanded(
          child: following
              ? StatTile(
                  value: remaining == null ? '--' : fmt.distance(remaining),
                  label: l10n.statToGo,
                )
              : StatTile(
                  value: UnitFormatter.durationClock(
                    Duration(seconds: stats.movingSeconds),
                  ),
                  label: l10n.statMoving,
                ),
        ),
      ],
    );
  }
}

/// The rest of the live stats, below the fold of the recording sheet: on a
/// route the ETA as a clock time (Naismith scaled by the hiker's own pace;
/// AllTrails has no ETA) and the climbing left, then moving time, gain, pace,
/// and elevation.
class RecordingDetailGrid extends ConsumerWidget {
  const RecordingDetailGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(recordingProvider);
    final stats = state.stats;
    final following = state.routeLengthM != null;

    var etaText = '--';
    final eta = state.etaSeconds;
    if (eta != null && state.status == RecordingStatus.recording) {
      final at = DateTime.now().add(Duration(seconds: eta.round()));
      etaText = DateFormat.jm().format(at);
    }
    final gainLeft = state.remainingGainM;

    final tiles = <Widget>[
      if (following) ...[
        StatTile(value: etaText, label: l10n.statEta),
        StatTile(
          value: gainLeft == null ? '--' : fmt.elevation(gainLeft),
          label: l10n.statGainLeft,
        ),
        StatTile(
          value: UnitFormatter.durationClock(
            Duration(seconds: stats.movingSeconds),
          ),
          label: l10n.statMoving,
        ),
      ],
      StatTile(value: fmt.elevationSigned(stats.gainM), label: l10n.statGain),
      StatTile(value: fmt.pace(stats.currentSpeedMps), label: l10n.statPace),
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
      childAspectRatio: 1.7,
      children: tiles,
    );
  }
}
