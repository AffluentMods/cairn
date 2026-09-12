// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import '../../core/geo/nearest_point.dart';

/// Ground meters per screen pixel at [zoom] for a Web Mercator map (256 px
/// tiles), used to turn a touch tolerance into a distance.
double metersPerPixel(double lat, double zoom) =>
    156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);

/// Where a tap on the route line should insert a new waypoint (spec Phase 3:
/// "tap a route leg to insert a waypoint mid-leg").
///
/// Returns the index to insert at (between two existing waypoints) when the
/// tap lies within [toleranceM] of [polyline], or null when it is off the
/// line, so the caller appends instead. Waypoints are located along the line
/// by their nearest segment; the tap goes between the pair that brackets it,
/// or after the nearest waypoint when the legs double back on themselves.
int? insertIndexForTap(
  List<List<double>> polyline,
  List<List<double>> waypoints,
  double lat,
  double lon, {
  required double toleranceM,
}) {
  if (polyline.length < 2 || waypoints.length < 2) return null;
  final tap = nearestPointOnPolyline(lat, lon, polyline);
  if (tap == null || tap.distanceM > toleranceM) return null;
  final tapPos = tap.segmentIndex + tap.t;

  final positions = <double>[];
  for (final w in waypoints) {
    final np = nearestPointOnPolyline(w[0], w[1], polyline);
    positions.add(np == null ? 0 : np.segmentIndex + np.t);
  }
  for (var i = 0; i < positions.length - 1; i++) {
    final a = positions[i], b = positions[i + 1];
    final lo = math.min(a, b), hi = math.max(a, b);
    if (tapPos >= lo && tapPos <= hi) return i + 1;
  }
  // Not bracketed (the line loops back): insert after the nearest waypoint,
  // never before the first or after the last.
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < positions.length; i++) {
    final d = (positions[i] - tapPos).abs();
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best.clamp(1, positions.length - 1);
}
