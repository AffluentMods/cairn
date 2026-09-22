// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../domain/models/forest_road.dart';
import '../../../l10n/app_localizations.dart';

/// The card for a forest road or motorized trail tapped on the map: number
/// and name, whether it is open all year or for a season, which vehicles may
/// use it and when, surface, maintenance level, and the MVUM caveat.
Future<void> showRoadCard(BuildContext context, ForestRoad road) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _RoadCard(road: road),
  );
}

class _RoadCard extends ConsumerWidget {
  const _RoadCard({required this.road});
  final ForestRoad road;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = ref.watch(unitFormatterProvider);
    final title = road.isTrail
        ? l10n.roadTrailTitle(road.number)
        : l10n.roadTitle(road.number);
    final surface = _surfaceText(l10n, road.surfaceCode);
    final maint = _maintText(l10n, road.maintLevelCode);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  road.isTrail
                      ? Icons.two_wheeler_outlined
                      : Icons.directions_car_outlined,
                  size: 28,
                  color: scheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            if (road.name != null) ...[
              const SizedBox(height: 2),
              Text(road.name!, style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  text:
                      road.seasonal ? l10n.roadSeasonal : l10n.roadOpenAllYear,
                  emphasized: !road.seasonal,
                ),
                if (surface != null)
                  _Chip(text: '${l10n.roadSurface}: $surface'),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.roadOpenTo, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            if (road.access.isEmpty)
              Text(l10n.roadNotOpen, style: theme.textTheme.bodyMedium)
            else
              for (final a in road.access)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(_vehicleText(l10n, a.vehicle),
                            style: theme.textTheme.bodyMedium),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        a.yearlong
                            ? l10n.roadAllYear
                            : _seasonText(l10n, a.dates),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: a.yearlong ? scheme.onSurface : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            if (maint != null) ...[
              const SizedBox(height: 10),
              Text('${l10n.roadMaintenance}: $maint',
                  style: theme.textTheme.bodyMedium),
            ],
            if (road.lengthMi != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.roadLength(fmt.distance(road.lengthMi! * 1609.344)),
                style: muted,
              ),
            ],
            const SizedBox(height: 14),
            Text(l10n.roadMvumNote, style: muted),
            const SizedBox(height: 4),
            Text(l10n.attributionUsfs, style: muted),
          ],
        ),
      ),
    );
  }

  static String _vehicleText(AppLocalizations l10n, String vehicle) =>
      switch (vehicle) {
        'passengerVehicle' => l10n.roadVehiclePassenger,
        'highClearance' => l10n.roadVehicleHighClearance,
        'truck' => l10n.roadVehicleTruck,
        'motorhome' => l10n.roadVehicleMotorhome,
        'fourWd' => l10n.roadVehicleFourWd,
        'atv' => l10n.roadVehicleAtv,
        'motorcycle' => l10n.roadVehicleMotorcycle,
        _ => l10n.roadVehicleOtherOhv,
      };

  static String? _surfaceText(AppLocalizations l10n, String? code) =>
      switch (code) {
        'AGG' => l10n.roadSurfaceGravel,
        'NAT' => l10n.roadSurfaceNative,
        'AC' || 'P' || 'PAV' => l10n.roadSurfacePaved,
        'BST' => l10n.roadSurfaceChipSeal,
        'IMP' => l10n.roadSurfaceImproved,
        'PCC' => l10n.roadSurfaceConcrete,
        _ => null,
      };

  static String? _maintText(AppLocalizations l10n, String? level) =>
      switch (level) {
        '1' => l10n.roadMaint1,
        '2' => l10n.roadMaint2,
        '3' => l10n.roadMaint3,
        '4' => l10n.roadMaint4,
        '5' => l10n.roadMaint5,
        _ => null,
      };

  /// "04/02-11/30" as "Apr 2 to Nov 30"; anything else as published.
  static String _seasonText(AppLocalizations l10n, String dates) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})-(\d{1,2})/(\d{1,2})$')
        .firstMatch(dates.trim());
    if (m == null) return dates;
    String day(int month, int d) =>
        DateFormat.MMMd().format(DateTime(2024, month, d));
    return l10n.roadSeason(
      day(int.parse(m[1]!), int.parse(m[2]!)),
      day(int.parse(m[3]!), int.parse(m[4]!)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.emphasized = false});
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
