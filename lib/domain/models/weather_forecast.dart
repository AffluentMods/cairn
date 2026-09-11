// SPDX-License-Identifier: GPL-3.0-or-later

/// One hour of weather (spec Phase 7).
class WeatherHour {
  const WeatherHour({
    required this.time,
    required this.tempC,
    this.precipProbability,
    this.windMps,
    this.gustMps,
    this.cloudCover,
    this.shortForecast,
  });
  final DateTime time;
  final double tempC;
  final int? precipProbability;
  final double? windMps;
  final double? gustMps;
  final int? cloudCover;
  final String? shortForecast;
}

/// A weather forecast for one location (trailhead or high point).
class WeatherForecast {
  const WeatherForecast({
    required this.label,
    required this.elevationM,
    required this.hours,
    this.source = 'NWS',
  });
  final String label; // "trailhead" or "high point"
  final double elevationM;
  final List<WeatherHour> hours;
  final String source;

  WeatherHour? get current => hours.isEmpty ? null : hours.first;
}

/// An active weather alert (spec Phase 7). Red Flag Warning is the one hikers
/// care most about in fire season.
class WeatherAlert {
  const WeatherAlert({
    required this.event,
    this.severity,
    this.ends,
  });
  final String event;
  final String? severity;
  final DateTime? ends;

  bool get isRedFlag => event.toLowerCase().contains('red flag');
}
