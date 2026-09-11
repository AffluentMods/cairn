// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// The eight named moon phases (spec Section 10 l10n keys).
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  full,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Moon phase and illuminated fraction for an instant (spec Section 8, Phase 7).
/// Uses the mean synodic cycle from a known new-moon epoch (Meeus, simplified),
/// which is accurate to a couple of percent for illumination, plenty for
/// headlamp planning.
class MoonInfo {
  const MoonInfo({
    required this.age,
    required this.illumination,
    required this.phase,
  });

  /// Days since the last new moon (0 to ~29.53).
  final double age;

  /// Illuminated fraction, 0 (new) to 1 (full).
  final double illumination;

  final MoonPhase phase;

  /// Illumination as a whole-number percentage.
  int get illuminationPercent => (illumination * 100).round();
}

const double _synodicMonth = 29.530588853;

// Reference new moon: 2000-01-06 18:14 UTC (Julian day 2451550.259722).
const double _epochNewMoonJd = 2451550.259722;

double _julianDate(DateTime utc) {
  final d = utc.toUtc();
  var year = d.year;
  var month = d.month;
  final dayFrac = d.day +
      (d.hour + (d.minute + (d.second + d.millisecond / 1000) / 60) / 60) /
          24.0;
  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  final a = (year / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (year + 4716)).floor() +
      (30.6001 * (month + 1)).floor() +
      dayFrac +
      b -
      1524.5;
}

MoonInfo computeMoon(DateTime instant) {
  final jd = _julianDate(instant);
  var age = (jd - _epochNewMoonJd) % _synodicMonth;
  if (age < 0) age += _synodicMonth;

  // Illuminated fraction from the phase angle. 0 at new, 1 at full.
  final phaseAngle = 2 * math.pi * age / _synodicMonth;
  final illumination = (1 - math.cos(phaseAngle)) / 2;

  final phase = _phaseForAge(age);
  return MoonInfo(age: age, illumination: illumination, phase: phase);
}

MoonPhase _phaseForAge(double age) {
  // Eight equal-ish bins across the synodic month, with the four principal
  // phases as narrow windows around their exact fractions.
  final f = age / _synodicMonth; // 0..1
  const eighth = 1 / 8;
  const half = eighth / 2;
  if (f < half || f >= 1 - half) return MoonPhase.newMoon;
  if (f < eighth + half) return MoonPhase.waxingCrescent;
  if (f < 2 * eighth + half) return MoonPhase.firstQuarter;
  if (f < 3 * eighth + half) return MoonPhase.waxingGibbous;
  if (f < 4 * eighth + half) return MoonPhase.full;
  if (f < 5 * eighth + half) return MoonPhase.waningGibbous;
  if (f < 6 * eighth + half) return MoonPhase.lastQuarter;
  return MoonPhase.waningCrescent;
}
