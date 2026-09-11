// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../domain/models/air_quality.dart';
import '../../domain/models/fire_restriction.dart';

/// Client for the Affluent Labs proxy (spec Section 8), which holds the API keys
/// the app must not ship. Optional: the app works without it (Open-Meteo model
/// AQI, no restrictions). Response shapes match the cairn-proxy backend.
class AffluentProxySource {
  AffluentProxySource(this._dio, this.baseUrl);

  final Dio _dio;
  final String baseUrl; // e.g. https://tiles.affluentlabs.dev or the proxy host

  /// EPA AirNow monitor AQI (spec 5.6), the max AQI across reported parameters.
  Future<AirQuality?> airNowAqi(double lat, double lon) async {
    final json = await _get('/v1/aqi', {'lat': '$lat', 'lon': '$lon'});
    final obs = (json?['observations'] as List?) ?? const [];
    if (obs.isEmpty) return null;
    var maxAqi = 0;
    for (final o in obs) {
      final v = (o as Map)['AQI'];
      if (v is num && v.toInt() > maxAqi) maxAqi = v.toInt();
    }
    return AirQuality(currentAqi: maxAqi, source: AqiSource.monitor);
  }

  /// Current fire restrictions per land unit.
  Future<List<FireRestriction>> restrictions() async {
    final json = await _get('/v1/restrictions.json', const {});
    final units = (json?['units'] as List?) ?? const [];
    return [
      for (final u in units.cast<Map<String, dynamic>>())
        FireRestriction(
          name: u['name']?.toString() ?? '',
          stage: (u['stage'] as num?)?.toInt() ?? 0,
          summary: u['summary']?.toString() ?? '',
          source: u['source']?.toString(),
          since: u['since']?.toString(),
        ),
    ];
  }

  /// NPS park alerts (raw alert objects), or empty.
  Future<List<Map<String, dynamic>>> npsAlerts(List<String> parkCodes) async {
    final json = await _get('/v1/nps/alerts', {'parks': parkCodes.join(',')});
    return ((json?['alerts'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// Recreation.gov facilities near a point (raw facility objects), or empty.
  Future<List<Map<String, dynamic>>> ridbFacilities(
    double lat,
    double lon, {
    int radius = 25,
  }) async {
    final json = await _get('/v1/ridb/facilities', {
      'lat': '$lat',
      'lon': '$lon',
      'radius': '$radius',
    });
    return ((json?['facilities'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> params,
  ) async {
    try {
      final res = await _dio.get<dynamic>(
        '$baseUrl$path',
        queryParameters: params.isEmpty ? null : params,
        options: Options(responseType: ResponseType.json),
      );
      final data = res.data;
      if (res.statusCode == 200 && data is Map<String, dynamic>) return data;
      return null;
    } on DioException {
      return null; // proxy down: caller degrades to no-key sources
    }
  }
}
