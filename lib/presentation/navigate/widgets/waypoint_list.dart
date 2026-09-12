// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/units/unit_formatter.dart';
import '../../../domain/usecases/water_along_route.dart';
import '../route_editor_provider.dart';

/// The ordered waypoint list. Swipe a row to delete (spec Section 9.6). Rows
/// read as "Start", "Waypoint 2 ... 2.3 mi", "End", with the distance along
/// the route instead of raw coordinates; off-trail waypoints are marked.
class WaypointList extends ConsumerWidget {
  const WaypointList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(routeEditorProvider);
    final waypoints = state.waypoints;
    if (waypoints.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.planEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    final polyline = state.polyline;
    return Column(
      children: [
        for (var i = 0; i < waypoints.length; i++)
          Dismissible(
            key: ValueKey('wp_$i${waypoints[i].lat}${waypoints[i].lon}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Theme.of(context).colorScheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) =>
                ref.read(routeEditorProvider.notifier).removeAt(i),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 13,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                i == 0
                    ? l10n.planWaypointStart
                    : i == waypoints.length - 1
                        ? l10n.planWaypointEnd
                        : l10n.planWaypointN(i + 1),
              ),
              subtitle: _alongText(polyline, waypoints[i], i, fmt),
              trailing: waypoints[i].onTrail
                  ? null
                  : Text(
                      l10n.planOffTrail,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
            ),
          ),
      ],
    );
  }

  /// "2.3 mi" along the route, or nothing for the start and while the route
  /// has not been built yet.
  Widget? _alongText(
    List<List<double>> polyline,
    EditorWaypoint w,
    int index,
    UnitFormatter fmt,
  ) {
    if (index == 0 || polyline.length < 2) return null;
    final d = distanceAlong(polyline, w.lat, w.lon);
    if (d == null) return null;
    return Text(fmt.distance(d.distanceAlongM));
  }
}
