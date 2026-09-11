// SPDX-License-Identifier: GPL-3.0-or-later
import 'nearest_point.dart';

/// Ray-casting point-in-polygon for a single ring of `[lat, lon]` points.
/// Good for the modest areas of a fire perimeter or wilderness boundary.
bool pointInRing(double lat, double lon, List<List<double>> ring) {
  var inside = false;
  final n = ring.length;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final yi = ring[i][0], xi = ring[i][1];
    final yj = ring[j][0], xj = ring[j][1];
    final intersect = ((yi > lat) != (yj > lat)) &&
        (lon <
            (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// True if the point is inside any of the rings. Geometry is stored as a flat
/// list of rings ([lat, lon] points), one per polygon outer boundary; holes are
/// not modeled (they do not matter for fire or wilderness proximity).
bool pointInAnyRing(
  double lat,
  double lon,
  List<List<List<double>>> rings,
) {
  for (final ring in rings) {
    if (ring.length >= 3 && pointInRing(lat, lon, ring)) return true;
  }
  return false;
}

/// Minimum distance in meters from a point to a ring's edges (the ring treated
/// as a closed polyline).
double distanceToRingMeters(double lat, double lon, List<List<double>> ring) {
  if (ring.length < 2) return double.infinity;
  final closed = ring.first == ring.last ? ring : [...ring, ring.first];
  final np = nearestPointOnPolyline(lat, lon, closed);
  return np?.distanceM ?? double.infinity;
}
