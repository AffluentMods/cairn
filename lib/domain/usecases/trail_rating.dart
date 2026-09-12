// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import '../../core/geo/haversine.dart';

/// Difficulty bands, from the Shenandoah / NPS rating (docs/DECISIONS.md).
enum TrailDifficulty { easy, moderate, hard, strenuous }

/// How a line closes: a loop, an out-and-back, or point to point (one way).
enum RouteType { loop, outAndBack, pointToPoint }

/// The NPS numeric rating: sqrt(2 x gain in feet x distance in miles). Shown
/// with the label so the rating is explainable, which AllTrails' is not.
double difficultyScore({required double distanceM, required double gainM}) {
  final miles = distanceM / 1609.344;
  final feet = gainM / 0.3048;
  return math.sqrt(2 * feet * miles);
}

/// Maps the score to a band (Easy under 50, Moderate to 140, Hard to 250,
/// Strenuous above) and bumps one band for terrain that needs hands or a
/// nose for the route: `sac_scale` T3 and up, or `trail_visibility` bad,
/// horrible, or no. Checked against AllTrails' labels for seven Washington
/// and Arizona trails in the benchmark; all seven matched.
TrailDifficulty difficultyLevel(
  double score, {
  String? sacScale,
  String? trailVisibility,
}) {
  var level = score < 50
      ? TrailDifficulty.easy
      : score < 140
          ? TrailDifficulty.moderate
          : score < 250
              ? TrailDifficulty.hard
              : TrailDifficulty.strenuous;
  const hardSac = {
    'demanding_mountain_hiking',
    'alpine_hiking',
    'demanding_alpine_hiking',
    'difficult_alpine_hiking',
  };
  const hardVisibility = {'bad', 'horrible', 'no'};
  if (hardSac.contains(sacScale) || hardVisibility.contains(trailVisibility)) {
    final i = TrailDifficulty.values.indexOf(level);
    level = TrailDifficulty
        .values[math.min(i + 1, TrailDifficulty.values.length - 1)];
  }
  return level;
}

/// A "typical hiker" time in seconds: the pace fitted to AllTrails' published
/// bands in the benchmark (about 5.35 km/h plus one hour per 248 m of gain),
/// which absorbs rests and the descent. Naismith and Langmuir (the "fit"
/// estimate in `computeRouteStats`) runs shorter.
double typicalTimeSeconds({required double distanceM, required double gainM}) {
  final hours = distanceM / 1000.0 / 5.35 + gainM / 248.0;
  return hours * 3600.0;
}

/// Rounds a time down to a half-hour band like the trail pages the benchmark
/// sampled: (from, to) in hours, never under (0.5, 1).
({double from, double to}) hoursBand(double seconds) {
  final h = seconds / 3600.0;
  final from = math.max(0.5, (h * 2).floor() / 2.0);
  return (from: from, to: from + 0.5);
}

/// Classifies a `[lat, lon]` line. A loop starts and ends within 100 m without
/// retracing itself; an out-and-back retraces at least 70 percent of its
/// second half over its first half (within 30 m); anything else is point to
/// point. Sampled every ~50 m so a long trail stays cheap.
RouteType routeTypeOf(List<List<double>> line) {
  if (line.length < 3) return RouteType.pointToPoint;
  final samples = _every(line, 50);
  if (samples.length < 4) return RouteType.pointToPoint;
  final half = samples.length ~/ 2;
  final first = samples.sublist(0, half);
  final second = samples.sublist(half);
  var retraced = 0;
  for (final p in second) {
    for (final q in first) {
      if (haversineMeters(p[0], p[1], q[0], q[1]) <= 30) {
        retraced++;
        break;
      }
    }
  }
  final overlap = retraced / second.length;
  final closes = haversineMeters(
        line.first[0],
        line.first[1],
        line.last[0],
        line.last[1],
      ) <=
      100;
  if (overlap >= 0.7) return RouteType.outAndBack;
  if (closes && overlap < 0.3) return RouteType.loop;
  return RouteType.pointToPoint;
}

List<List<double>> _every(List<List<double>> line, double stepM) {
  final out = <List<double>>[line.first];
  var since = 0.0;
  for (var i = 1; i < line.length; i++) {
    since +=
        haversineMeters(line[i - 1][0], line[i - 1][1], line[i][0], line[i][1]);
    if (since >= stepM) {
      out.add(line[i]);
      since = 0;
    }
  }
  if (!identical(out.last, line.last)) out.add(line.last);
  return out;
}
