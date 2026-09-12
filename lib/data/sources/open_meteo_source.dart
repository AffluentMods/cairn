// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../domain/models/air_quality.dart';
import '../../domain/models/weather_forecast.dart';

/// Open-Meteo: model air quality and a no-key weather fallback (spec Sections
/// 5.5, 5.6). Values are requested in SI (Celsius, meters per second).
class OpenMeteoSource {
  OpenMeteoSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>?> fetchAirQuality(double lat, double lon) =>
      _get('https://air-quality-api.open-meteo.com/v1/air-quality', {
        'latitude': '$lat',
        'longitude': '$lon',
        'hourly': 'us_aqi,pm2_5',
        'forecast_days': '3',
      });

  Future<Map<String, dynamic>?> fetchForecast(
    double lat,
    double lon,
    double elevationM,
  ) =>
      _get('https://api.open-meteo.com/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'hourly':
            'temperature_2m,precipitation_probability,wind_speed_10m,wind_gusts_10m,cloud_cover',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'ms',
        'forecast_days': '7',
        'elevation': '${elevationM.round()}',
      });

  /// Elevations (meters, Copernicus 90 m) for up to 100 `[lat, lon]` points,
  /// the fallback when no terrain tile is cached or reachable. Null on any
  /// failure; the list is parallel to [latLon].
  Future<List<double?>?> fetchElevations(List<List<double>> latLon) async {
    if (latLon.isEmpty || latLon.length > 100) return null;
    final json = await _get('https://api.open-meteo.com/v1/elevation', {
      'latitude': latLon.map((p) => p[0].toStringAsFixed(5)).join(','),
      'longitude': latLon.map((p) => p[1].toStringAsFixed(5)).join(','),
    });
    final elev = json?['elevation'];
    if (elev is! List || elev.length != latLon.length) return null;
    return [for (final e in elev) e is num ? e.toDouble() : null];
  }

  Future<Map<String, dynamic>?> _get(
    String url,
    Map<String, String> params,
  ) async {
    try {
      final res = await _dio.get<dynamic>(
        url,
        queryParameters: params,
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

int _nowIndex(List<dynamic> times) {
  final now = DateTime.now();
  var best = 0;
  var bestDiff = const Duration(days: 3650);
  for (var i = 0; i < times.length; i++) {
    final t = DateTime.tryParse(times[i].toString());
    if (t == null) continue;
    final diff = t.difference(now).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = i;
    }
  }
  return best;
}

AirQuality? parseOpenMeteoAqi(Map<String, dynamic> json) {
  final hourly = json['hourly'] as Map<String, dynamic>?;
  if (hourly == null) return null;
  final times = (hourly['time'] as List?) ?? const [];
  final aqi = (hourly['us_aqi'] as List?) ?? const [];
  final pm = (hourly['pm2_5'] as List?) ?? const [];
  if (times.isEmpty || aqi.isEmpty) return null;
  final idx = _nowIndex(times);
  final points = <AqiPoint>[];
  for (var i = 0; i < times.length && i < aqi.length; i++) {
    final v = aqi[i];
    final t = DateTime.tryParse(times[i].toString());
    if (v is num && t != null) points.add(AqiPoint(t, v.round()));
  }
  final current = aqi[idx.clamp(0, aqi.length - 1)];
  return AirQuality(
    currentAqi: current is num ? current.round() : 0,
    source: AqiSource.model,
    hourly: points,
    pm25: (idx < pm.length && pm[idx] is num)
        ? (pm[idx] as num).toDouble()
        : null,
  );
}

WeatherForecast? parseOpenMeteoForecast(
  Map<String, dynamic> json, {
  required String label,
  required double elevationM,
}) {
  final hourly = json['hourly'] as Map<String, dynamic>?;
  if (hourly == null) return null;
  final times = (hourly['time'] as List?) ?? const [];
  final temp = (hourly['temperature_2m'] as List?) ?? const [];
  final precip = (hourly['precipitation_probability'] as List?) ?? const [];
  final wind = (hourly['wind_speed_10m'] as List?) ?? const [];
  final gust = (hourly['wind_gusts_10m'] as List?) ?? const [];
  final cloud = (hourly['cloud_cover'] as List?) ?? const [];
  if (times.isEmpty || temp.isEmpty) return null;

  final start = _nowIndex(times);
  final hours = <WeatherHour>[];
  for (var i = start; i < times.length && i < start + 48; i++) {
    final t = DateTime.tryParse(times[i].toString());
    if (t == null || i >= temp.length || temp[i] is! num) continue;
    hours.add(
      WeatherHour(
        time: t,
        tempC: (temp[i] as num).toDouble(),
        precipProbability: (i < precip.length && precip[i] is num)
            ? (precip[i] as num).round()
            : null,
        windMps: (i < wind.length && wind[i] is num)
            ? (wind[i] as num).toDouble()
            : null,
        gustMps: (i < gust.length && gust[i] is num)
            ? (gust[i] as num).toDouble()
            : null,
        cloudCover: (i < cloud.length && cloud[i] is num)
            ? (cloud[i] as num).round()
            : null,
      ),
    );
  }
  return WeatherForecast(
    label: label,
    elevationM: elevationM,
    hours: hours,
    source: 'Open-Meteo',
  );
}
