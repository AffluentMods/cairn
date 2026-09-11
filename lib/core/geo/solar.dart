// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// Sunrise, sunset, and civil twilight for a date and coordinate, using the NOAA
/// solar position algorithm (spec Section 8, Phase 7). All returned instants are
/// UTC; format them in the device's local time zone at the edge.
///
/// [date] is the local civil date (its year, month, day are used); [lat] and
/// [lon] are degrees (east positive, so western US longitudes are negative).
class SolarTimes {
  const SolarTimes({
    required this.sunrise,
    required this.sunset,
    required this.civilDawn,
    required this.civilDusk,
    required this.solarNoon,
    required this.polarNight,
    required this.polarDay,
  });

  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? civilDawn;
  final DateTime? civilDusk;
  final DateTime solarNoon;

  /// True at extreme latitudes where the sun never rises on this date.
  final bool polarNight;

  /// True where the sun never sets on this date.
  final bool polarDay;

  /// Length of daylight (sunrise to sunset). Zero on polar night, 24 h on polar day.
  Duration get daylight {
    if (polarDay) return const Duration(hours: 24);
    if (polarNight || sunrise == null || sunset == null) return Duration.zero;
    return sunset!.difference(sunrise!);
  }
}

double _rad(double d) => d * math.pi / 180.0;
double _deg(double r) => r * 180.0 / math.pi;

/// Julian day at 00:00 UTC of the given calendar date.
double _julianDay(int year, int month, int day) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day +
      b -
      1524.5;
}

SolarTimes computeSolarTimes(DateTime date, double lat, double lon) {
  final jd = _julianDay(date.year, date.month, date.day);
  final t = (jd - 2451545.0) / 36525.0;

  final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360.0;
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final c = math.sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
      math.sin(_rad(3 * m)) * 0.000289;
  final trueLong = l0 + c;
  final appLong =
      trueLong - 0.00569 - 0.00478 * math.sin(_rad(125.04 - 1934.136 * t));
  final meanObliq = 23.0 +
      (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) /
          60.0;
  final obliqCorr = meanObliq + 0.00256 * math.cos(_rad(125.04 - 1934.136 * t));
  final declRad =
      math.asin(math.sin(_rad(obliqCorr)) * math.sin(_rad(appLong)));

  final y = math.tan(_rad(obliqCorr / 2)) * math.tan(_rad(obliqCorr / 2));
  final eqTime = 4.0 *
      _deg(
        y * math.sin(2 * _rad(l0)) -
            2 * e * math.sin(_rad(m)) +
            4 * e * y * math.sin(_rad(m)) * math.cos(2 * _rad(l0)) -
            0.5 * y * y * math.sin(4 * _rad(l0)) -
            1.25 * e * e * math.sin(2 * _rad(m)),
      );

  final solarNoonMin = 720.0 - 4.0 * lon - eqTime;
  final dayBase = DateTime.utc(date.year, date.month, date.day);
  final solarNoon = dayBase.add(Duration(seconds: (solarNoonMin * 60).round()));

  ({DateTime? rise, DateTime? set, bool night, bool day}) forZenith(
    double zenithDeg,
  ) {
    final cosH =
        math.cos(_rad(zenithDeg)) / (math.cos(_rad(lat)) * math.cos(declRad)) -
            math.tan(_rad(lat)) * math.tan(declRad);
    if (cosH > 1.0) {
      // Sun stays below this zenith all day.
      return (rise: null, set: null, night: true, day: false);
    }
    if (cosH < -1.0) {
      // Sun stays above this zenith all day.
      return (rise: null, set: null, night: false, day: true);
    }
    final ha = _deg(math.acos(cosH));
    final riseMin = 720.0 - 4.0 * (lon + ha) - eqTime;
    final setMin = 720.0 - 4.0 * (lon - ha) - eqTime;
    return (
      rise: dayBase.add(Duration(seconds: (riseMin * 60).round())),
      set: dayBase.add(Duration(seconds: (setMin * 60).round())),
      night: false,
      day: false,
    );
  }

  // 90.833 deg accounts for refraction and the sun's radius; 96 deg is civil.
  final official = forZenith(90.833);
  final civil = forZenith(96.0);

  return SolarTimes(
    sunrise: official.rise,
    sunset: official.set,
    civilDawn: civil.rise,
    civilDusk: civil.set,
    solarNoon: solarNoon,
    polarNight: official.night,
    polarDay: official.day,
  );
}
