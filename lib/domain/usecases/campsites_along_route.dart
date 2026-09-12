// SPDX-License-Identifier: GPL-3.0-or-later
import 'water_along_route.dart';

/// A place to camp found near a route (spec Phase 8): an OSM camp site, hut
/// or shelter within [campsitesAlongRoute]'s offset of the line.
class CampPoint {
  const CampPoint({
    required this.distanceAlongM,
    required this.offsetM,
    required this.kind,
    this.name,
  });

  final double distanceAlongM;
  final double offsetM;
  final String kind; // camp_site, hut, shelter
  final String? name;
}

/// A candidate camp POI for [campsitesAlongRoute].
class CampCandidate {
  const CampCandidate({
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

/// POI kinds that count as a place to sleep.
const campKinds = {'camp_site', 'hut', 'shelter'};

/// Camps within [maxOffsetM] of the route, ordered by distance along it
/// (spec Phase 8: `tourism=camp_site` within 300 m, with distance-along).
List<CampPoint> campsitesAlongRoute(
  List<List<double>> route,
  List<CampCandidate> candidates, {
  double maxOffsetM = 300,
}) {
  if (route.length < 2) return const [];
  final camps = <CampPoint>[];
  for (final c in candidates) {
    if (!campKinds.contains(c.kind)) continue;
    final d = distanceAlong(route, c.lat, c.lon);
    if (d == null || d.offsetM > maxOffsetM) continue;
    camps.add(CampPoint(
      distanceAlongM: d.distanceAlongM,
      offsetM: d.offsetM,
      kind: c.kind,
      name: c.name,
    ));
  }
  camps.sort((a, b) => a.distanceAlongM.compareTo(b.distanceAlongM));
  return camps;
}
