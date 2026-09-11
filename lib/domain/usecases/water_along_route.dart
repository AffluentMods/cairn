// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';
import '../../core/geo/nearest_point.dart';
import 'compute_route_stats.dart';

/// A water source found along a route (spec Phase 8).
class WaterPoint {
  const WaterPoint({
    required this.distanceAlongM,
    required this.offsetM,
    required this.kind,
    this.name,
    this.lastBeforeClimb = false,
  });

  final double distanceAlongM;
  final double offsetM; // distance from the route
  final String kind; // spring, drinking_water, stream, water (lake)
  final String? name;
  final bool lastBeforeClimb;

  WaterPoint copyWith({bool? lastBeforeClimb}) => WaterPoint(
        distanceAlongM: distanceAlongM,
        offsetM: offsetM,
        kind: kind,
        name: name,
        lastBeforeClimb: lastBeforeClimb ?? this.lastBeforeClimb,
      );
}

/// A candidate water POI for [waterAlongRoute].
class WaterCandidate {
  const WaterCandidate({
    required this.lat,
    required this.lon,
    required this.kind,
    this.name,
  });
  final double lat;
  final double lon;
  final String kind;
  final String? name;
}

/// Cumulative distance along [route] to the nearest point to (lat, lon), plus
/// how far off the route that source sits.
({double distanceAlongM, double offsetM})? distanceAlong(
  List<List<double>> route,
  double lat,
  double lon,
) {
  final np = nearestPointOnPolyline(lat, lon, route);
  if (np == null) return null;
  var along = 0.0;
  for (var i = 0; i < np.segmentIndex && i < route.length - 1; i++) {
    along += haversineMeters(
      route[i][0],
      route[i][1],
      route[i + 1][0],
      route[i + 1][1],
    );
  }
  if (np.segmentIndex < route.length - 1) {
    along += haversineMeters(
          route[np.segmentIndex][0],
          route[np.segmentIndex][1],
          route[np.segmentIndex + 1][0],
          route[np.segmentIndex + 1][1],
        ) *
        np.t;
  }
  return (distanceAlongM: along, offsetM: np.distanceM);
}

/// Water sources within [maxOffsetM] of the route, ordered by distance along it,
/// with the last source before the longest sustained climb flagged (spec Phase
/// 8). Pass [profile] to enable the "last before the climb" callout.
List<WaterPoint> waterAlongRoute(
  List<List<double>> route,
  List<WaterCandidate> candidates, {
  double maxOffsetM = 80,
  List<ProfilePoint> profile = const [],
}) {
  if (route.length < 2) return const [];
  final waters = <WaterPoint>[];
  for (final c in candidates) {
    final d = distanceAlong(route, c.lat, c.lon);
    if (d == null || d.offsetM > maxOffsetM) continue;
    waters.add(
      WaterPoint(
        distanceAlongM: d.distanceAlongM,
        offsetM: d.offsetM,
        kind: c.kind,
        name: c.name,
      ),
    );
  }
  waters.sort((a, b) => a.distanceAlongM.compareTo(b.distanceAlongM));

  final climbStart = _longestClimbStartDistance(profile);
  if (climbStart != null) {
    var lastIdx = -1;
    for (var i = 0; i < waters.length; i++) {
      if (waters[i].distanceAlongM <= climbStart) lastIdx = i;
    }
    if (lastIdx >= 0) {
      waters[lastIdx] = waters[lastIdx].copyWith(lastBeforeClimb: true);
    }
  }
  return waters;
}

/// Distance where the longest sustained ascent begins, or null.
double? _longestClimbStartDistance(List<ProfilePoint> profile) {
  if (profile.length < 2) return null;
  double? bestStart;
  var bestGain = 0.0;
  var runStart = profile.first.distanceM;
  var runStartElev = profile.first.elevM;
  var prevElev = profile.first.elevM;
  for (var i = 1; i < profile.length; i++) {
    final e = profile[i].elevM;
    if (e < prevElev) {
      // Descent breaks the run; evaluate the run that just ended.
      final gain = prevElev - runStartElev;
      if (gain > bestGain) {
        bestGain = gain;
        bestStart = runStart;
      }
      runStart = profile[i].distanceM;
      runStartElev = e;
    }
    prevElev = e;
  }
  final gain = prevElev - runStartElev;
  if (gain > bestGain) bestStart = runStart;
  return bestStart;
}
