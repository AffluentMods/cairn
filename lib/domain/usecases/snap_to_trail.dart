// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/nearest_point.dart';
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
