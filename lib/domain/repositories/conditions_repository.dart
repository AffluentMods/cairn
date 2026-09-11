// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/moon.dart';
import '../../core/geo/solar.dart';
import '../models/air_quality.dart';
import '../models/fire_incident.dart';
import '../models/land_unit.dart';
import '../models/weather_forecast.dart';

/// Everything the conditions panel shows for a route or point (spec Phase 7).
class ConditionsBundle {
  const ConditionsBundle({
    required this.fires,
    required this.alerts,
    required this.land,
    required this.solar,
    required this.moon,
    required this.fetchedAt,
    this.aqi,
    this.weatherTrailhead,
    this.weatherHigh,
    this.stale = false,
  });

  final List<FireIncident>
      fires; // annotated with route proximity, nearest first
  final AirQuality? aqi;
  final WeatherForecast? weatherTrailhead;
  final WeatherForecast? weatherHigh;
  final List<WeatherAlert> alerts;
  final List<LandUnit> land; // units the route enters
  final SolarTimes solar;
  final MoonInfo moon;
  final DateTime fetchedAt;
  final bool stale;

  FireIncident? get nearestFire => fires.isEmpty ? null : fires.first;
}

/// Conditions data, cached so it shows offline with a freshness marker (spec
/// Phase 7).
abstract interface class ConditionsRepository {
  /// Active fires in the bbox (plus a buffer), for the map fire layer.
  Future<List<FireIncident>> firesInBbox(List<double> bbox);

  /// Land units (wilderness, forest, park) in the bbox, for the land layer.
  Future<List<LandUnit>> landInBbox(List<double> bbox);

  /// The full conditions bundle for a route: fires annotated by proximity, AQI
  /// and weather at the trailhead and high point, alerts, land entered, and
  /// daylight and moon for the date.
  Future<ConditionsBundle> forRoute({
    required List<List<double>> routePolyline,
    required double trailheadLat,
    required double trailheadLon,
    required double trailheadElevM,
    required double highLat,
    required double highLon,
    required double highElevM,
    required List<double> bbox,
    DateTime? date,
  });
}
