// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

/// Thrown when every Overpass endpoint fails. Callers fall back to cached data
/// and show a non-blocking banner (spec Phase 2 acceptance).
class OverpassUnavailable implements Exception {
  OverpassUnavailable([this.cause]);
  final Object? cause;
  @override
  String toString() => 'OverpassUnavailable($cause)';
}

/// Fetches trails and POIs from OpenStreetMap via Overpass, with mirror
/// fallback on rate limits (spec Section 5.2). One request at a time; callers
/// cache aggressively and never query more than a z10 cell's bbox.
class OverpassSource {
  OverpassSource(this._dio);

  final Dio _dio;

  static const endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  Future<Map<String, dynamic>> fetchWays(List<double> bbox) =>
      _run(waysQuery(bbox));

  Future<Map<String, dynamic>> fetchPois(List<double> bbox) =>
      _run(poisQuery(bbox));

  Future<Map<String, dynamic>> _run(String query) async {
    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await _dio.post<dynamic>(
          endpoint,
          data: {'data': query},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            // Fail over to the next mirror quickly instead of hanging (Fix Pass
            // 1: a slow Overpass must not make the app feel frozen).
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 40),
            responseType: ResponseType.json,
          ),
        );
        final status = response.statusCode ?? 0;
        if (status == 429 || status == 504 || status >= 500) {
          lastError = 'status $status';
          continue; // try the next mirror
        }
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        lastError = 'unexpected response type';
      } on DioException catch (e) {
        lastError = e;
        // Network/timeout: try the next mirror.
        continue;
      }
    }
    throw OverpassUnavailable(lastError);
  }

  /// bbox is (south, west, north, east).
  static String waysQuery(List<double> b) => '''
[out:json][timeout:35];
(
  way["highway"~"^(path|footway|track|bridleway|steps)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
  relation["route"~"^(hiking|foot)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
);
out body;
>;
out skel qt;''';

  static String poisQuery(List<double> b) => '''
[out:json][timeout:35];
(
  node["natural"~"^(spring|water|peak|saddle)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
  node["tourism"~"^(camp_site|wilderness_hut|viewpoint)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
  node["amenity"~"^(toilets|drinking_water|parking|shelter)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
  node["highway"="trailhead"](${b[0]},${b[1]},${b[2]},${b[3]});
  way["natural"="water"](${b[0]},${b[1]},${b[2]},${b[3]});
  way["waterway"~"^(stream|river)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
);
out body;
>;
out skel qt;''';
}
