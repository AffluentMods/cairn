// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../core/net/arcgis_query.dart';
import '../../domain/models/fire_incident.dart';
import 'usfs_source.dart' show pickField;

/// NIFC WFIGS wildfire data (spec Section 5.4): current perimeters (polygons)
/// and incident locations (points, including fires with no perimeter yet).
class NifcSource {
  NifcSource(this._dio);
  final Dio _dio;

  static const perimetersUrl =
      'https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Interagency_Perimeters_Current/FeatureServer/0';
  static const incidentsUrl =
      'https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Incident_Locations_Current/FeatureServer/0';

  Future<Map<String, dynamic>?> fetchPerimeters(List<double> bbox) =>
      _query(perimetersUrl, bbox);
  Future<Map<String, dynamic>?> fetchIncidents(List<double> bbox) =>
      _query(incidentsUrl, bbox);

  Future<Map<String, dynamic>?> _query(String base, List<double> bbox) async {
    try {
      final res = await _dio.getUri<dynamic>(ArcGisQuery.features(base, bbox));
      final data = res.data;
      if (res.statusCode == 200 && data is Map<String, dynamic>) return data;
      return null;
    } on DioException {
      return null;
    }
  }
}

DateTime? _epochMs(Object? v) {
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
  }
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Outer rings ([lat, lon]) from a GeoJSON Polygon or MultiPolygon geometry.
/// GeoJSON is [lon, lat]; the coordinates are swapped here.
List<List<List<double>>> ringsFromGeoJson(Map<String, dynamic>? geometry) {
  if (geometry == null) return const [];
  final type = geometry['type'];
  final coords = geometry['coordinates'];
  final out = <List<List<double>>>[];
  List<double> pt(dynamic c) =>
      [(c[1] as num).toDouble(), (c[0] as num).toDouble()];
  List<List<double>> ring(dynamic r) => [for (final c in (r as List)) pt(c)];
  if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
    out.add(ring(coords.first)); // outer ring only
  } else if (type == 'MultiPolygon' && coords is List) {
    for (final poly in coords) {
      if (poly is List && poly.isNotEmpty) out.add(ring(poly.first));
    }
  }
  return out;
}

/// Parses NIFC perimeter and incident GeoJSON into fire incidents, deduping
/// point incidents that already have a perimeter of the same name.
List<FireIncident> parseFires({
  Map<String, dynamic>? perimeters,
  Map<String, dynamic>? incidents,
}) {
  final fires = <FireIncident>[];
  final namesWithPerimeter = <String>{};

  final perimeterFeatures =
      (perimeters?['features'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  for (final f in perimeterFeatures) {
    final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = pickField(props, [
          'poly_IncidentName',
          'IncidentName',
          'attr_IncidentName',
        ])?.toString() ??
        'Fire';
    final rings = ringsFromGeoJson(f['geometry'] as Map<String, dynamic>?);
    final type =
        pickField(props, ['attr_IncidentTypeCategory', 'IncidentTypeCategory'])
            ?.toString();
    namesWithPerimeter.add(name.toLowerCase());
    fires.add(
      FireIncident(
        id: 'perim_${f['id'] ?? name}',
        name: name,
        acres: (pickField(props, ['poly_GISAcres', 'GISAcres']) as num?)
            ?.toDouble(),
        percentContained:
            (pickField(props, ['attr_PercentContained', 'PercentContained'])
                    as num?)
                ?.round(),
        discoveredAt: _epochMs(
          pickField(
              props, ['attr_FireDiscoveryDateTime', 'FireDiscoveryDateTime']),
        ),
        modifiedAt: _epochMs(
          pickField(props,
              ['attr_ModifiedOnDateTime_dt', 'poly_ModifiedOnDateTime_dt']),
        ),
        behavior: pickField(props, ['attr_FireBehaviorGeneral'])?.toString(),
        prescribed: type == 'RX',
        polygons: rings,
      ),
    );
  }

  final incidentFeatures =
      (incidents?['features'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  for (final f in incidentFeatures) {
    final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final name =
        pickField(props, ['attr_IncidentName', 'IncidentName'])?.toString() ??
            'Fire';
    // Skip an incident point that already has a perimeter of the same name.
    if (namesWithPerimeter.contains(name.toLowerCase())) continue;
    final geom = f['geometry'] as Map<String, dynamic>?;
    final coords = geom?['coordinates'];
    double? lat;
    double? lon;
    if (coords is List && coords.length >= 2) {
      lon = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }
    final type = pickField(props, ['attr_IncidentTypeCategory'])?.toString();
    fires.add(
      FireIncident(
        id: 'inc_${f['id'] ?? name}',
        name: name,
        acres:
            (pickField(props, ['attr_IncidentSize', 'attr_DailyAcres']) as num?)
                ?.toDouble(),
        percentContained:
            (pickField(props, ['attr_PercentContained']) as num?)?.round(),
        discoveredAt:
            _epochMs(pickField(props, ['attr_FireDiscoveryDateTime'])),
        modifiedAt: _epochMs(pickField(props, ['attr_ModifiedOnDateTime_dt'])),
        prescribed: type == 'RX',
        lat: lat,
        lon: lon,
      ),
    );
  }

  return fires;
}
