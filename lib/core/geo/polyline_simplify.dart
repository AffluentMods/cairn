// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'haversine.dart';

/// Ramer-Douglas-Peucker simplification of a `[lat, lon]` polyline, with the
/// tolerance given in meters. Used to keep the trails GeoJSON under the feature
/// budget at low zoom (spec Section 8, Phase 2) without distorting the line.
List<List<double>> simplifyDouglasPeucker(
  List<List<double>> points,
  double toleranceMeters,
) {
  if (points.length < 3 || toleranceMeters <= 0) {
    return List<List<double>>.from(points);
  }
  final keep = List<bool>.filled(points.length, false);
  keep[0] = true;
  keep[points.length - 1] = true;
  _simplify(points, 0, points.length - 1, toleranceMeters, keep);

  final out = <List<double>>[];
  for (var i = 0; i < points.length; i++) {
    if (keep[i]) out.add(points[i]);
  }
  return out;
}

void _simplify(
  List<List<double>> pts,
  int first,
  int last,
  double tol,
  List<bool> keep,
) {
  if (last <= first + 1) return;
  var maxDist = 0.0;
  var index = first;
  for (var i = first + 1; i < last; i++) {
    final d = _perpDistanceMeters(pts[i], pts[first], pts[last]);
    if (d > maxDist) {
      maxDist = d;
      index = i;
    }
  }
  if (maxDist > tol) {
    keep[index] = true;
    _simplify(pts, first, index, tol, keep);
    _simplify(pts, index, last, tol, keep);
  }
}

/// Perpendicular distance in meters from point [p] to the segment [a]-[b], using
/// a local equirectangular projection (accurate for the short spans in a trail).
double _perpDistanceMeters(
  List<double> p,
  List<double> a,
  List<double> b,
) {
  final lat0 = _rad(a[0]);
  const mPerDegLat = kEarthRadiusM * math.pi / 180.0;
  final mPerDegLon = mPerDegLat * math.cos(lat0);

  double x(List<double> q) => q[1] * mPerDegLon;
  double y(List<double> q) => q[0] * mPerDegLat;

  final px = x(p), py = y(p);
  final ax = x(a), ay = y(a);
  final bx = x(b), by = y(b);

  final dx = bx - ax;
  final dy = by - ay;
  final segLenSq = dx * dx + dy * dy;
  if (segLenSq == 0) {
    final ex = px - ax, ey = py - ay;
    return math.sqrt(ex * ex + ey * ey);
  }
  var t = ((px - ax) * dx + (py - ay) * dy) / segLenSq;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx;
  final cy = ay + t * dy;
  final ex = px - cx, ey = py - cy;
  return math.sqrt(ex * ex + ey * ey);
}

double _rad(double deg) => deg * math.pi / 180.0;
