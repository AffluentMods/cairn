// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/nearest_point.dart';
import '../../core/worker/geo_worker.dart';
import 'route_between_waypoints.dart';

/// The outcome of snapping a tapped point to the nearest trail.
class SnapResult {
  const SnapResult({
    required this.point,
    required this.onTrail,
    required this.snapDistanceM,
  });

  final SnappedPoint point;
  final bool onTrail;
  final double snapDistanceM;
}

/// Off-trail waypoints carry this sentinel way id so the router produces a
/// dashed straight leg rather than pretending to follow a trail.
const int offTrailWayId = -999;

/// Snaps a tapped coordinate to the nearest cached way within [maxDistM] meters
/// (spec Section 8, Phase 3). Beyond that, the waypoint is off-trail and the
/// router draws a straight, flagged leg.
SnapResult snapToTrail(
  double lat,
  double lon,
  List<RoutableWay> ways, {
  double maxDistM = 40,
}) {
  NearestPoint? best;
  RoutableWay? bestWay;
  for (final way in ways) {
    if (way.penalty.isInfinite) continue;
    final np = nearestPointOnPolyline(lat, lon, way.coords);
    if (np == null) continue;
    if (best == null || np.distanceM < best.distanceM) {
      best = np;
      bestWay = way;
    }
  }

  if (best != null && bestWay != null && best.distanceM <= maxDistM) {
    return SnapResult(
      point: SnappedPoint(
        wayId: bestWay.id,
        segmentIndex: best.segmentIndex,
        lat: best.lat,
        lon: best.lon,
      ),
      onTrail: true,
      snapDistanceM: best.distanceM,
    );
  }

  return SnapResult(
    point: SnappedPoint(
      wayId: offTrailWayId,
      segmentIndex: 0,
      lat: lat,
      lon: lon,
    ),
    onTrail: false,
    snapDistanceM: best?.distanceM ?? double.infinity,
  );
}

/// A route built across a whole waypoint list: the joined polyline, whether any
/// leg went off-trail, and whether each input waypoint snapped to a trail
/// (aligned with the input order).
class BuiltRoute {
  const BuiltRoute({
    required this.polyline,
    required this.offTrail,
    required this.onTrail,
  });

  final List<List<double>> polyline; // [[lat, lon], ...]
  final bool offTrail;
  final List<bool> onTrail;

  static const empty =
      BuiltRoute(polyline: [], offTrail: false, onTrail: []);
}

/// Snaps every `[lat, lon]` waypoint to [ways] and routes each leg, joining the
/// legs into one polyline. Pure and self-contained so the whole snap-and-route
/// pass runs in a single worker isolate, copying [ways] once (Fix Pass 1
/// X1.3.1, H3).
BuiltRoute buildRoute(List<RoutableWay> ways, List<List<double>> waypoints) {
  if (waypoints.length < 2) return BuiltRoute.empty;
  final snapped = <SnapResult>[
    for (final w in waypoints) snapToTrail(w[0], w[1], ways),
  ];
  final polyline = <List<double>>[];
  var offTrail = false;
  for (var i = 0; i < snapped.length - 1; i++) {
    final leg = routeBetweenWaypoints(
      ways,
      snapped[i].point,
      snapped[i + 1].point,
    );
    if (leg.offTrail) offTrail = true;
    final pts = leg.polyline;
    if (i == 0) {
      polyline.addAll(pts);
    } else if (pts.isNotEmpty) {
      polyline.addAll(pts.skip(1)); // avoid duplicating the shared vertex
    }
  }
  return BuiltRoute(
    polyline: polyline,
    offTrail: offTrail,
    onTrail: [for (final s in snapped) s.onTrail],
  );
}

/// [buildRoute] on a worker isolate.
Future<BuiltRoute> buildRouteAsync(
  List<RoutableWay> ways,
  List<List<double>> waypoints,
) =>
    GeoWorker.run('route', () => buildRoute(ways, waypoints));
