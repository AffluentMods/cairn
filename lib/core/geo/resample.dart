// SPDX-License-Identifier: GPL-3.0-or-later
import 'haversine.dart';

/// A point sampled along a route, with its cumulative distance from the start.
class SampledPoint {
  const SampledPoint(this.lat, this.lon, this.distanceM);
  final double lat;
  final double lon;
  final double distanceM;
}

/// Resamples a `[lat, lon]` polyline to points spaced [spacingM] meters apart
/// (spec Section 8, Phase 3: sample every 20 m before elevation lookup). Keeps
/// the exact start and end. Returns the input as a single sample when too short.
List<SampledPoint> resampleByDistance(
  List<List<double>> line,
  double spacingM,
) {
  if (line.isEmpty) return const [];
  if (line.length == 1) {
    return [SampledPoint(line.first[0], line.first[1], 0)];
  }
  final out = <SampledPoint>[SampledPoint(line.first[0], line.first[1], 0)];
  var carried = 0.0; // distance since the last emitted sample
  var total = 0.0;

  for (var i = 0; i < line.length - 1; i++) {
    final aLat = line[i][0], aLon = line[i][1];
    final bLat = line[i + 1][0], bLon = line[i + 1][1];
    final segLen = haversineMeters(aLat, aLon, bLat, bLon);
    if (segLen == 0) continue;

    var distOnSeg = spacingM - carried;
    while (distOnSeg < segLen) {
      final f = distOnSeg / segLen;
      final lat = aLat + (bLat - aLat) * f;
      final lon = aLon + (bLon - aLon) * f;
      out.add(SampledPoint(lat, lon, total + distOnSeg));
      distOnSeg += spacingM;
    }
    carried = segLen - (distOnSeg - spacingM);
    total += segLen;
  }

  final last = line.last;
  if (out.last.distanceM < total - 0.01) {
    out.add(SampledPoint(last[0], last[1], total));
  }
  return out;
}

/// The `[lat, lon]` point at [distanceM] along a polyline, or null if the line
/// is empty. Used to place the elevation-profile scrubber marker on the map.
List<double>? pointAtDistance(List<List<double>> line, double distanceM) {
  if (line.isEmpty) return null;
  if (line.length == 1 || distanceM <= 0) return line.first;
  var acc = 0.0;
  for (var i = 0; i < line.length - 1; i++) {
    final segLen = haversineMeters(
      line[i][0],
      line[i][1],
      line[i + 1][0],
      line[i + 1][1],
    );
    if (acc + segLen >= distanceM) {
      final f = segLen == 0 ? 0.0 : (distanceM - acc) / segLen;
      return [
        line[i][0] + (line[i + 1][0] - line[i][0]) * f,
        line[i][1] + (line[i + 1][1] - line[i][1]) * f,
      ];
    }
    acc += segLen;
  }
  return line.last;
}
