// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/haversine.dart';
import '../../data/data_providers.dart';
import '../../domain/models/trail.dart';
import '../map_common/map_providers.dart';

/// One named trail in the current viewport, assembled for the Explore list
/// (Addendum A4.1). Named ways that share a name are merged into one entry.
class NearbyTrail {
  const NearbyTrail({
    required this.trail,
    required this.lengthM,
    required this.distanceM,
    required this.centerLat,
    required this.centerLon,
    required this.geometry,
  });

  /// A representative way (prefers one carrying a USFS number), used to open the
  /// detail sheet and as the stable id source.
  final Trail trail;

  /// Summed length of the named ways in view.
  final double lengthM;

  /// Distance from the map center to the nearest point on the trail.
  final double distanceM;
  final double centerLat;
  final double centerLon;
  final List<List<double>> geometry;

  String get id => 'w${trail.id}';
  String get name => trail.name ?? '';
  String? get usfsNumber => trail.usfsNumber;
}

/// Named trails in the current viewport, sorted by distance from the map center
/// and capped at 50 (Addendum A4.1). Reads only from the local DB (the map's
/// own overlay refresh already ensured the area), so this is cheap and offline.
final nearbyTrailsProvider = FutureProvider<List<NearbyTrail>>((ref) async {
  final vp = ref.watch(viewportProvider);
  if (vp == null) return const [];
  final trails = await ref.read(trailRepositoryProvider).trailsInBbox(vp.bbox);

  final byName = <String, List<Trail>>{};
  for (final t in trails) {
    final name = t.name;
    if (name == null || name.isEmpty) continue;
    if (t.geometry.isEmpty) continue;
    // Forest roads (highway=track) stay on the map but not in this list
    // (Fix Pass 1 X1.3.3).
    if (t.highway == 'track') continue;
    (byName[name] ??= <Trail>[]).add(t);
  }

  final centerLat = (vp.south + vp.north) / 2;
  final centerLon = (vp.west + vp.east) / 2;

  final out = <NearbyTrail>[];
  byName.forEach((name, ways) {
    final geometry = <List<double>>[for (final w in ways) ...w.geometry];
    if (geometry.isEmpty) return;
    var length = 0.0;
    for (final w in ways) {
      length += w.lengthM;
    }
    var nearest = double.infinity;
    for (final p in geometry) {
      final d = haversineMeters(centerLat, centerLon, p[0], p[1]);
      if (d < nearest) nearest = d;
    }
    final mid = geometry[geometry.length ~/ 2];
    final rep = ways.firstWhere(
      (w) => w.usfsNumber != null,
      orElse: () => ways.first,
    );
    out.add(NearbyTrail(
      trail: rep,
      lengthM: length,
      distanceM: nearest,
      centerLat: mid[0],
      centerLon: mid[1],
      geometry: geometry,
    ));
  });

  out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
  return out.take(30).toList();
});
