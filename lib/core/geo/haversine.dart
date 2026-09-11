// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// Mean Earth radius in meters. Good to ~0.1% for hiking distances.
const double kEarthRadiusM = 6371000.0;

double _rad(double deg) => deg * math.pi / 180.0;

/// Great-circle distance in meters between two coordinates (haversine).
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return kEarthRadiusM * c;
}

/// Total length in meters of a polyline given as `[lat, lon]` pairs.
double polylineLengthMeters(List<List<double>> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += haversineMeters(
      points[i - 1][0],
      points[i - 1][1],
      points[i][0],
      points[i][1],
    );
  }
  return total;
}

/// Initial bearing in degrees (0 = north, clockwise) from point 1 to point 2.
double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final dLon = _rad(lon2 - lon1);
  final y = math.sin(dLon) * math.cos(_rad(lat2));
  final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(dLon);
  final brng = math.atan2(y, x) * 180.0 / math.pi;
  return (brng + 360.0) % 360.0;
}
