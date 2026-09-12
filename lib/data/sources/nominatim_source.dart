// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../domain/models/place_hit.dart';

/// Place search through OpenStreetMap's Nominatim (spec Section 13 "Search").
///
/// Follows the public usage policy: one request per second at most, no
/// type-ahead (the sheet searches on submit only), an identifying User-Agent
/// (the shared Dio client), and repeated queries served from a small cache.
class NominatimSource {
  NominatimSource(this._dio);
  final Dio _dio;

  static final endpoint =
      Uri.parse('https://nominatim.openstreetmap.org/search');
  static const minInterval = Duration(seconds: 1);
  static const _cacheSize = 30;

  DateTime? _lastRequest;
  final _cache = <String, List<PlaceHit>>{};

  /// Up to five places for [query], an empty list when none match, or null
  /// when the request failed (offline, rate limited, server error).
  Future<List<PlaceHit>?> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final key = q.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final last = _lastRequest;
    if (last != null) {
      final wait = minInterval - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();
    try {
      final res = await _dio.getUri<dynamic>(
        endpoint.replace(queryParameters: {
          'q': q,
          'format': 'jsonv2',
          'limit': '5',
        }),
      );
      final data = res.data;
      if (res.statusCode != 200 || data is! List) return null;
      final hits = parseNominatim(data);
      if (_cache.length >= _cacheSize) _cache.remove(_cache.keys.first);
      _cache[key] = hits;
      return hits;
    } on DioException {
      return null;
    }
  }
}

/// Parses a `format=jsonv2` result list. Entries without a usable position
/// are skipped.
List<PlaceHit> parseNominatim(List<dynamic> json) {
  final out = <PlaceHit>[];
  for (final e in json) {
    if (e is! Map) continue;
    final lat = double.tryParse(e['lat']?.toString() ?? '');
    final lon = double.tryParse(e['lon']?.toString() ?? '');
    if (lat == null || lon == null) continue;
    final display = e['display_name']?.toString() ?? '';
    var name = e['name']?.toString() ?? '';
    if (name.isEmpty) name = display.split(',').first.trim();
    if (name.isEmpty) continue;
    final bbox = e['boundingbox'];
    double? south, north, west, east;
    if (bbox is List && bbox.length == 4) {
      south = double.tryParse(bbox[0].toString());
      north = double.tryParse(bbox[1].toString());
      west = double.tryParse(bbox[2].toString());
      east = double.tryParse(bbox[3].toString());
    }
    out.add(PlaceHit(
      name: name,
      displayName: display,
      lat: lat,
      lon: lon,
      south: south ?? lat,
      north: north ?? lat,
      west: west ?? lon,
      east: east ?? lon,
      kind: e['type']?.toString(),
    ));
  }
  return out;
}
