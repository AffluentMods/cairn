// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'haversine.dart';

/// The closest point on a polyline to a query coordinate.
class NearestPoint {
  const NearestPoint({
    required this.lat,
    required this.lon,
    required this.distanceM,
    required this.segmentIndex,
    required this.t,
  });

  /// Snapped coordinate on the line.
  final double lat;
  final double lon;

  /// Distance from the query point to the snapped point, meters.
  final double distanceM;

  /// Index i such that the snapped point lies on segment [i, i+1].
  final int segmentIndex;

  /// Fraction (0..1) along that segment.
  final double t;
}

/// Nearest point on a `[lat, lon]` polyline to (qLat, qLon), using a local
/// equirectangular projection (accurate over the short spans of a trail).
/// Returns null for a line with fewer than two points. [start] and [end]
/// restrict the search to segments `start <= i < end` so a live follower can
/// look near its last match first.
NearestPoint? nearestPointOnPolyline(
  double qLat,
  double qLon,
  List<List<double>> line, {
  int start = 0,
  int? end,
}) {
  if (line.length < 2) return null;
  final lat0 = qLat * math.pi / 180.0;
  const mPerDegLat = kEarthRadiusM * math.pi / 180.0;
  final mPerDegLon = mPerDegLat * math.cos(lat0);

  double x(double lon) => lon * mPerDegLon;
  double y(double lat) => lat * mPerDegLat;

  final px = x(qLon), py = y(qLat);
  NearestPoint? best;

  final from = start.clamp(0, line.length - 1);
  final to = (end ?? line.length - 1).clamp(0, line.length - 1);
  for (var i = from; i < to; i++) {
    final ax = x(line[i][1]), ay = y(line[i][0]);
    final bx = x(line[i + 1][1]), by = y(line[i + 1][0]);
    final dx = bx - ax, dy = by - ay;
    final segLenSq = dx * dx + dy * dy;
    var t = segLenSq == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / segLenSq;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    final dist = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
    if (best == null || dist < best.distanceM) {
      final snapLat = line[i][0] + (line[i + 1][0] - line[i][0]) * t;
      final snapLon = line[i][1] + (line[i + 1][1] - line[i][1]) * t;
      best = NearestPoint(
        lat: snapLat,
        lon: snapLon,
        distanceM: dist,
        segmentIndex: i,
        t: t,
      );
    }
  }
  return best;
}
