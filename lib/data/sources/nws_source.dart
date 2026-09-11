// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../domain/models/weather_forecast.dart';

/// NOAA National Weather Service (spec Section 5.5). Requires the Cairn
/// User-Agent, which the shared Dio client injects. US only; the repository
/// falls back to Open-Meteo on any failure or outside the US.
class NwsSource {
  NwsSource(this._dio);
  final Dio _dio;

  /// Returns the forecastHourly URL for a coordinate, or null.
  Future<String?> hourlyUrl(double lat, double lon) async {
    final json = await _get('https://api.weather.gov/points/$lat,$lon');
    final props = json?['properties'] as Map<String, dynamic>?;
    return props?['forecastHourly'] as String?;
  }

  Future<Map<String, dynamic>?> fetchHourly(String url) => _get(url);

  Future<Map<String, dynamic>?> fetchAlerts(double lat, double lon) =>
      _get('https://api.weather.gov/alerts/active?point=$lat,$lon');

  Future<Map<String, dynamic>?> _get(String url) async {
    try {
      final res = await _dio.get<dynamic>(
        url,
        options: Options(responseType: ResponseType.json),
      );
      final data = res.data;
      if (res.statusCode == 200 && data is Map<String, dynamic>) return data;
      return null;
    } on DioException {
      return null;
    }
  }
}

double? _fToC(num? t, String? unit) {
  if (t == null) return null;
  if (unit == 'F' || unit == null) return (t.toDouble() - 32) * 5 / 9;
  return t.toDouble();
}

/// Parses "10 mph" or "5 to 10 mph" into meters per second (the higher number).
double? _windToMps(Object? v) {
  if (v is num) return v.toDouble() * 0.44704;
  if (v is String) {
    final nums = RegExp(r'\d+')
        .allMatches(v)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a > b ? a : b) * 0.44704;
  }
  return null;
}

WeatherForecast? parseNwsHourly(
  Map<String, dynamic> json, {
  required String label,
  required double elevationM,
}) {
  final periods =
      (json['properties']?['periods'] as List?)?.cast<Map<String, dynamic>>();
  if (periods == null || periods.isEmpty) return null;
  final hours = <WeatherHour>[];
  for (final p in periods.take(48)) {
    final t = DateTime.tryParse(p['startTime']?.toString() ?? '');
    final tempC =
        _fToC(p['temperature'] as num?, p['temperatureUnit'] as String?);
    if (t == null || tempC == null) continue;
    final pop = (p['probabilityOfPrecipitation'] as Map?)?['value'];
    hours.add(
      WeatherHour(
        time: t,
        tempC: tempC,
        precipProbability: pop is num ? pop.round() : null,
        windMps: _windToMps(p['windSpeed']),
        gustMps: _windToMps(p['windGust']),
        shortForecast: p['shortForecast'] as String?,
      ),
    );
  }
  if (hours.isEmpty) return null;
  return WeatherForecast(label: label, elevationM: elevationM, hours: hours);
}

List<WeatherAlert> parseNwsAlerts(Map<String, dynamic> json) {
  final features =
      (json['features'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final alerts = <WeatherAlert>[];
  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>?;
    final event = props?['event'] as String?;
    if (event == null) continue;
    alerts.add(
      WeatherAlert(
        event: event,
        severity: props?['severity'] as String?,
        ends: DateTime.tryParse(props?['ends']?.toString() ?? ''),
      ),
    );
  }
  return alerts;
}
