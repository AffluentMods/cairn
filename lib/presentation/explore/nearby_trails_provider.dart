// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/haversine.dart';
import '../../core/worker/geo_worker.dart';
import '../../data/data_providers.dart';
import '../../domain/models/trail.dart';
import '../../domain/usecases/chain_ways.dart';
import '../map_common/map_providers.dart';

/// One named trail in the current viewport, assembled for the Explore list
/// and the trail detail sheet (Addendum A4.1). Named ways that share a name
/// are merged into one entry and chained into a continuous line.
class NearbyTrail {
  const NearbyTrail({
    required this.trail,
    required this.ways,
    required this.lengthM,
    required this.distanceM,
    required this.centerLat,
    required this.centerLon,
    required this.geometry,
    required this.navGeometry,
  });

  /// A single way (a map tap or a search hit) as its own entry.
  factory NearbyTrail.single(Trail trail) => buildNearbyTrail(
        [trail],
        (trail.geometry.isEmpty ? const [0.0, 0.0] : trail.geometry.first)[0],
        (trail.geometry.isEmpty ? const [0.0, 0.0] : trail.geometry.first)[1],
      );

  /// A representative way (prefers one carrying a USFS number), used as the
  /// stable id source.
  final Trail trail;

  /// Every way in the group, for tags such as SAC scale and visibility.
  final List<Trail> ways;

  /// Summed length of the named ways in view.
  final double lengthM;

  /// Distance from the map center to the nearest point on the trail.
  final double distanceM;
  final double centerLat;
  final double centerLon;

  /// Every vertex of every way, for framing and highlighting.
  final List<List<double>> geometry;

  /// The longest continuous chain of the ways, in walking order, for the
  /// profile, the rating, and Navigate.
  final List<List<double>> navGeometry;

  String get id => 'w${trail.id}';
  String get name => trail.name ?? '';
  String? get usfsNumber => trail.usfsNumber;

  /// The most demanding SAC grade across the ways, or null.
  String? get sacScale {
    const order = [
      'hiking',
      'mountain_hiking',
      'demanding_mountain_hiking',
      'alpine_hiking',
      'demanding_alpine_hiking',
      'difficult_alpine_hiking',
    ];
    String? worst;
    for (final w in ways) {
      final s = w.sacScale;
      if (s == null) continue;
      if (worst == null || order.indexOf(s) > order.indexOf(worst)) worst = s;
    }
    return worst;
  }

  /// The poorest trail visibility across the ways, or null.
  String? get trailVisibility {
    const order = [
      'excellent',
      'good',
      'intermediate',
      'bad',
      'horrible',
      'no'
    ];
    String? worst;
    for (final w in ways) {
      final v = w.trailVisibility;
      if (v == null) continue;
      if (worst == null || order.indexOf(v) > order.indexOf(worst)) worst = v;
    }
    return worst;
  }

  /// Surfaces seen across the ways, most common first.
  List<String> get surfaces {
    final counts = <String, int>{};
    for (final w in ways) {
      final s = w.surface;
      if (s != null && s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
    }
    final out = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return out;
  }

  bool get informal => ways.every((w) => w.informal);
}

/// Named trails in the current viewport, sorted by distance from the map center
/// and capped at 30 (Addendum A4.1, Fix Pass 1 X1.3.3). Reads only from the
/// local DB (the map's own overlay refresh already ensured the area), so this
/// is cheap and offline. The grouping, chaining, and per-point distance loop
/// run off the UI isolate (Fix Pass 1 X1.3.1, H2).
final nearbyTrailsProvider = FutureProvider<List<NearbyTrail>>((ref) async {
  final vp = ref.watch(viewportProvider);
  if (vp == null) return const [];
  final trails = await ref.read(trailRepositoryProvider).trailsInBbox(vp.bbox);
  if (trails.isEmpty) return const [];

  final centerLat = (vp.south + vp.north) / 2;
  final centerLon = (vp.west + vp.east) / 2;

  return GeoWorker.run(
    'nearby-trails',
    () => buildNearbyTrails(trails, centerLat, centerLon),
  );
});

/// Groups named ways by name, chains and sums them, and finds each group's
/// nearest point to the map center. Pure and top-level so it can run in a
/// worker isolate.
List<NearbyTrail> buildNearbyTrails(
  List<Trail> trails,
  double centerLat,
  double centerLon,
) {
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

  final out = <NearbyTrail>[];
  byName.forEach((name, ways) {
    out.add(buildNearbyTrail(ways, centerLat, centerLon));
  });

  out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
  return out.take(30).toList();
}

/// One entry from a group of same-named ways.
NearbyTrail buildNearbyTrail(
  List<Trail> ways,
  double centerLat,
  double centerLon,
) {
  final geometry = <List<double>>[for (final w in ways) ...w.geometry];
  var length = 0.0;
  for (final w in ways) {
    length += w.lengthM;
  }
  var nearest = double.infinity;
  for (final p in geometry) {
    final d = haversineMeters(centerLat, centerLon, p[0], p[1]);
    if (d < nearest) nearest = d;
  }
  final mid =
      geometry.isEmpty ? const [0.0, 0.0] : geometry[geometry.length ~/ 2];
  final rep = ways.firstWhere(
    (w) => w.usfsNumber != null,
    orElse: () => ways.first,
  );
  final chains = chainWays([for (final w in ways) w.geometry]);
  return NearbyTrail(
    trail: rep,
    ways: ways,
    lengthM: length,
    distanceM: nearest.isFinite ? nearest : 0,
    centerLat: mid[0],
    centerLon: mid[1],
    geometry: geometry,
    navGeometry: chains.isEmpty ? geometry : chains.first,
  );
}
