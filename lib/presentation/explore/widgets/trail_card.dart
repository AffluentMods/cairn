// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/elevation_stats.dart';
import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../data/data_providers.dart';
import '../../saved/library_providers.dart';
import '../nearby_trails_provider.dart';

/// Per-trail gain, computed once from the DEM and reused across rebuilds.
final _gainCache = <String, double>{};

/// One row in the Explore "Trails in view" list (Addendum A4.1): name, USFS
/// chip, length and gain (gain loads lazily), distance from the map center, and
/// a heart that saves the trail.
class TrailCard extends ConsumerWidget {
  const TrailCard({required this.trail, required this.onTap, super.key});

  final NearbyTrail trail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final savedIds = ref.watch(savedTrailIdsProvider).valueOrNull ?? const {};
    final saved = savedIds.contains(trail.id);
    final displayName = trail.name.isEmpty ? l10n.trailUnnamed : trail.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (trail.usfsNumber != null) ...[
                        const SizedBox(width: 8),
                        _Chip(text: '#${trail.usfsNumber}'),
                      ],
                      if (trail.sectionInView) ...[
                        const SizedBox(width: 8),
                        _Chip(text: l10n.exploreSectionInView),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: saved ? l10n.trailUnsave : l10n.trailSave,
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: saved ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  onPressed: () => ref.read(favoritesRepositoryProvider).toggle(
                        trailId: trail.id,
                        name: displayName,
                        centerLat: trail.centerLat,
                        centerLon: trail.centerLon,
                        lengthM: trail.lengthM,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Row(
                children: [
                  _LengthAndGain(trail: trail),
                  const Spacer(),
                  Text(
                    l10n.exploreDistanceAway(fmt.distance(trail.distanceM)),
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LengthAndGain extends ConsumerWidget {
  const _LengthAndGain({required this.trail});

  final NearbyTrail trail;

  Future<double?> _gain(WidgetRef ref) async {
    final cached = _gainCache[trail.id];
    if (cached != null) return cached;
    try {
      final dem = await ref
          .read(elevationRepositoryProvider)
          .elevationsAlong(trail.geometry);
      if (dem.isEmpty) return null; // unknown offline: show nothing, not +0
      final gl = gainLoss(dem);
      _gainCache[trail.id] = gl.gain;
      return gl.gain;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(unitFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return FutureBuilder<double?>(
      future: _gain(ref),
      builder: (context, snap) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fmt.distance(trail.lengthM), style: style),
            const SizedBox(width: 10),
            if (snap.connectionState != ConnectionState.done)
              _Shimmer(color: scheme.surfaceContainerHighest)
            else if (snap.data != null) ...[
              Icon(Icons.north_east, size: 13, color: scheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(fmt.elevation(snap.data!), style: style),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
