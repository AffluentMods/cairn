// SPDX-License-Identifier: GPL-3.0-or-later

/// EPA AQI categories (spec Phase 7).
enum AqiCategory { good, moderate, usg, unhealthy, veryUnhealthy, hazardous }

/// Whether the value is a model estimate (Open-Meteo) or a monitor reading
/// (EPA AirNow via the proxy).
enum AqiSource { model, monitor }

/// Maps a US AQI value to its EPA category by the standard breakpoints.
AqiCategory aqiCategory(int aqi) {
  if (aqi <= 50) return AqiCategory.good;
  if (aqi <= 100) return AqiCategory.moderate;
  if (aqi <= 150) return AqiCategory.usg;
  if (aqi <= 200) return AqiCategory.unhealthy;
  if (aqi <= 300) return AqiCategory.veryUnhealthy;
  return AqiCategory.hazardous;
}

/// One hour of the AQI forecast, for the sparkline.
class AqiPoint {
  const AqiPoint(this.time, this.aqi);
  final DateTime time;
  final int aqi;
}

/// Air quality at a point (spec Phase 7).
class AirQuality {
  const AirQuality({
    required this.currentAqi,
    required this.source,
    this.hourly = const [],
    this.pm25,
  });

  final int currentAqi;
  final AqiSource source;
  final List<AqiPoint> hourly;
  final double? pm25;

  AqiCategory get category => aqiCategory(currentAqi);
}
