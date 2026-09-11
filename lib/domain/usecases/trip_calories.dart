// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// One integration step for calorie estimation.
class CalorieSegment {
  const CalorieSegment({
    required this.distanceM,
    required this.elevDeltaM,
    required this.seconds,
  });
  final double distanceM;
  final double elevDeltaM;
  final double seconds;
}

/// Default body mass when the user has not set one (spec Phase 6): label the
/// result an estimate.
const double kDefaultBodyKg = 75;

/// Pandolf load-carriage metabolic rate in watts (spec Phase 6):
///   M = 1.5W + 2.0(W+L)(L/W)^2 + n(W+L)(1.5V^2 + 0.35VG)
/// W body mass kg, L load kg, V speed m/s, G grade percent, n terrain factor.
/// Clamped to standing metabolism so steep descents never go negative.
double pandolfWatts({
  required double bodyKg,
  required double loadKg,
  required double speedMps,
  required double gradePercent,
  double terrain = 1.2,
}) {
  if (bodyKg <= 0) return 0;
  final w = bodyKg;
  final l = loadKg;
  final v = speedMps;
  final g = gradePercent;
  final m = 1.5 * w +
      2.0 * (w + l) * math.pow(l / w, 2) +
      terrain * (w + l) * (1.5 * v * v + 0.35 * v * g);
  return math.max(m, 1.5 * w);
}

/// Total trip calories (kcal) by integrating Pandolf watts over the segments.
/// 1 kcal = 4184 J.
double tripCaloriesKcal({
  required double bodyKg,
  required double packKg,
  required List<CalorieSegment> segments,
  double terrain = 1.2,
}) {
  var joules = 0.0;
  for (final s in segments) {
    if (s.seconds <= 0) continue;
    final speed = s.distanceM / s.seconds;
    final grade = s.distanceM > 0 ? s.elevDeltaM / s.distanceM * 100 : 0.0;
    final watts = pandolfWatts(
      bodyKg: bodyKg,
      loadKg: packKg,
      speedMps: speed,
      gradePercent: grade,
      terrain: terrain,
    );
    joules += watts * s.seconds;
  }
  return joules / 4184.0;
}
