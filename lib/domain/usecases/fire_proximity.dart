// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';
import '../../core/geo/polygon.dart';
import '../models/fire_incident.dart';

/// The route's relationship to a fire (spec Phase 7): whether it crosses the
/// perimeter, and if not, the nearest distance in meters.
typedef FireRelation = ({double distanceM, bool crosses});

/// Computes how close a route comes to one fire. For a perimeter, "crosses" is
/// true if any route point falls inside; otherwise the distance is the closest
/// approach to the perimeter. For a point-only incident, it is the closest
/// distance to that point.
FireRelation routeToFire(List<List<double>> route, FireIncident fire) {
  if (route.isEmpty) return (distanceM: double.infinity, crosses: false);

  if (fire.isPerimeter) {
    var minDist = double.infinity;
    for (final p in route) {
      if (pointInAnyRing(p[0], p[1], fire.polygons)) {
        return (distanceM: 0, crosses: true);
      }
      for (final ring in fire.polygons) {
        final d = distanceToRingMeters(p[0], p[1], ring);
        if (d < minDist) minDist = d;
      }
    }
    return (distanceM: minDist, crosses: false);
  }

  if (fire.lat == null || fire.lon == null) {
    return (distanceM: double.infinity, crosses: false);
  }
  var minDist = double.infinity;
  for (final p in route) {
    final d = haversineMeters(p[0], p[1], fire.lat!, fire.lon!);
    if (d < minDist) minDist = d;
  }
  return (distanceM: minDist, crosses: false);
}

/// Annotates each fire with its route relationship and returns them sorted by
/// distance (crossing fires first).
List<FireIncident> annotateFires(
  List<List<double>> route,
  List<FireIncident> fires,
) {
  final out = <FireIncident>[];
  for (final f in fires) {
    final rel = routeToFire(route, f);
    out.add(f.withProximity(distanceM: rel.distanceM, crosses: rel.crosses));
  }
  out.sort((a, b) {
    if (a.crossesRoute != b.crossesRoute) return a.crossesRoute ? -1 : 1;
    return (a.distanceToRouteM ?? double.infinity)
        .compareTo(b.distanceToRouteM ?? double.infinity);
  });
  return out;
}
