// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import '../../core/geo/moon.dart';
import '../../core/geo/polygon.dart';
import '../../core/geo/solar.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/models/fire_incident.dart';
import '../../domain/models/land_unit.dart';
import '../../domain/models/weather_forecast.dart';
import '../../domain/repositories/conditions_repository.dart';
import '../../domain/usecases/fire_proximity.dart';
import '../db/app_database.dart';
import '../sources/nifc_source.dart';
import '../sources/nws_source.dart';
import '../sources/open_meteo_source.dart';
import '../sources/usfs_source.dart';

typedef _Cached = ({
  Map<String, dynamic>? json,
  DateTime? fetchedAt,
  bool stale
});

class ConditionsRepositoryImpl implements ConditionsRepository {
  ConditionsRepositoryImpl({
    required this.db,
    required this.nifc,
    required this.nws,
    required this.openMeteo,
    required this.usfs,
  });

  final AppDatabase db;
  final NifcSource nifc;
  final NwsSource nws;
  final OpenMeteoSource openMeteo;
  final UsfsSource usfs;

  static const _fireTtl = Duration(minutes: 15);
  static const _weatherTtl = Duration(minutes: 60);
  static const _landTtl = Duration(days: 30);

  String _cell(List<double> bbox) =>
      bbox.map((v) => v.toStringAsFixed(1)).join(',');

  Future<_Cached> _cachedJson(
    String key,
    Duration ttl,
    Future<Map<String, dynamic>?> Function() fetch,
  ) async {
    final row = await (db.select(db.conditionsCache)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    final fresh = row != null && DateTime.now().difference(row.fetchedAt) < ttl;
    if (fresh) {
      return (
        json: jsonDecode(row.bodyJson) as Map<String, dynamic>,
        fetchedAt: row.fetchedAt,
        stale: false,
      );
    }
    final fetched = await fetch();
    if (fetched != null) {
      final now = DateTime.now();
      await db.into(db.conditionsCache).insertOnConflictUpdate(
            ConditionsCacheCompanion.insert(
              key: key,
              bodyJson: jsonEncode(fetched),
              fetchedAt: now,
            ),
          );
      return (json: fetched, fetchedAt: now, stale: false);
    }
    if (row != null) {
      return (
        json: jsonDecode(row.bodyJson) as Map<String, dynamic>,
        fetchedAt: row.fetchedAt,
        stale: true,
      );
    }
    return (json: null, fetchedAt: null, stale: true);
  }

  List<double> _buffer(List<double> bbox, double deg) =>
      [bbox[0] - deg, bbox[1] - deg, bbox[2] + deg, bbox[3] + deg];

  @override
  Future<List<FireIncident>> firesInBbox(List<double> bbox) async {
    // Buffer by ~50 miles so a fire just off screen still shows.
    final b = _buffer(bbox, 0.7);
    final perim = await _cachedJson(
      'fires:perim:${_cell(b)}',
      _fireTtl,
      () => nifc.fetchPerimeters(b),
    );
    final inc = await _cachedJson(
      'fires:inc:${_cell(b)}',
      _fireTtl,
      () => nifc.fetchIncidents(b),
    );
    return parseFires(perimeters: perim.json, incidents: inc.json);
  }

  @override
  Future<List<LandUnit>> landInBbox(List<double> bbox) async {
    final wild = await _cachedJson(
      'land:wild:${_cell(bbox)}',
      _landTtl,
      () => usfs.fetchWilderness(bbox),
    );
    final forest = await _cachedJson(
      'land:forest:${_cell(bbox)}',
      _landTtl,
      () => usfs.fetchForests(bbox),
    );
    return [
      ..._parseLand(wild.json, LandKind.wilderness, [
        'NAME',
        'WILDERNESS_NAME',
        'wildernessname',
      ]),
      ..._parseLand(forest.json, LandKind.forest, [
        'FORESTNAME',
        'NAME',
        'forestname',
      ]),
    ];
  }

  List<LandUnit> _parseLand(
    Map<String, dynamic>? geo,
    LandKind kind,
    List<String> nameFields,
  ) {
    final features =
        (geo?['features'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final out = <LandUnit>[];
    for (final f in features) {
      final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      final name = pickField(props, nameFields)?.toString() ?? 'Unnamed';
      final rings = ringsFromGeoJson(f['geometry'] as Map<String, dynamic>?);
      if (rings.isEmpty) continue;
      out.add(LandUnit(kind: kind, name: name, polygons: rings));
    }
    return out;
  }

  Future<({WeatherForecast? forecast, DateTime? fetchedAt, bool stale})>
      _weatherAt(double lat, double lon, double elevM, String label) async {
    // Try NWS first (mountain weather), fall back to Open-Meteo.
    final urlKey =
        'wx:nwsurl:${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final nwsHourly = await _cachedJson(urlKey, _weatherTtl, () async {
      final url = await nws.hourlyUrl(lat, lon);
      if (url == null) return null;
      return nws.fetchHourly(url);
    });
    if (nwsHourly.json != null) {
      final f =
          parseNwsHourly(nwsHourly.json!, label: label, elevationM: elevM);
      if (f != null) {
        return (
          forecast: f,
          fetchedAt: nwsHourly.fetchedAt,
          stale: nwsHourly.stale
        );
      }
    }
    final om = await _cachedJson(
      'wx:om:${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}',
      _weatherTtl,
      () => openMeteo.fetchForecast(lat, lon, elevM),
    );
    final f = om.json == null
        ? null
        : parseOpenMeteoForecast(om.json!, label: label, elevationM: elevM);
    return (forecast: f, fetchedAt: om.fetchedAt, stale: om.stale);
  }

  Future<({AirQuality? aqi, DateTime? fetchedAt, bool stale})> _aqiAt(
    double lat,
    double lon,
  ) async {
    final res = await _cachedJson(
      'aqi:${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
      _weatherTtl,
      () => openMeteo.fetchAirQuality(lat, lon),
    );
    final aqi = res.json == null ? null : parseOpenMeteoAqi(res.json!);
    return (aqi: aqi, fetchedAt: res.fetchedAt, stale: res.stale);
  }

  Future<({List<WeatherAlert> alerts, bool stale})> _alertsFor(
    double lat,
    double lon,
  ) async {
    final res = await _cachedJson(
      'alerts:${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
      const Duration(minutes: 30),
      () => nws.fetchAlerts(lat, lon),
    );
    return (
      alerts: res.json == null ? <WeatherAlert>[] : parseNwsAlerts(res.json!),
      stale: res.stale,
    );
  }

  @override
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
  }) async {
    final when = date ?? DateTime.now();
    final fires = annotateFires(routePolyline, await firesInBbox(bbox));
    final aqi = await _aqiAt(trailheadLat, trailheadLon);
    final wxTrail = await _weatherAt(
        trailheadLat, trailheadLon, trailheadElevM, 'trailhead');
    final wxHigh = await _weatherAt(highLat, highLon, highElevM, 'high point');
    final alerts = await _alertsFor(trailheadLat, trailheadLon);
    final land = await landInBbox(bbox);
    final entered = land
        .where(
          (u) =>
              routePolyline.any((p) => pointInAnyRing(p[0], p[1], u.polygons)),
        )
        .toList();

    final stale = aqi.stale || wxTrail.stale || wxHigh.stale || alerts.stale;
    final fetchedAt = [
      aqi.fetchedAt,
      wxTrail.fetchedAt,
      wxHigh.fetchedAt,
    ].whereType<DateTime>().fold<DateTime?>(
          null,
          (a, b) => a == null || b.isAfter(a) ? b : a,
        );

    return ConditionsBundle(
      fires: fires,
      aqi: aqi.aqi,
      weatherTrailhead: wxTrail.forecast,
      weatherHigh: wxHigh.forecast,
      alerts: alerts.alerts,
      land: entered,
      solar: computeSolarTimes(when, trailheadLat, trailheadLon),
      moon: computeMoon(when),
      fetchedAt: fetchedAt ?? DateTime.now(),
      stale: stale,
    );
  }
}
