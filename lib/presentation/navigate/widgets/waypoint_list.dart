// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../route_editor_provider.dart';

/// The ordered waypoint list. Swipe a row to delete (spec Section 9.6). Off-trail
/// waypoints are marked.
class WaypointList extends ConsumerWidget {
  const WaypointList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waypoints = ref.watch(routeEditorProvider).waypoints;
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
                '${waypoints[i].lat.toStringAsFixed(5)}, '
                '${waypoints[i].lon.toStringAsFixed(5)}',
              ),
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
}
