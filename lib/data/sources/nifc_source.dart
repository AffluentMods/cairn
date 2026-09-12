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
/// point incidents that already have a perimeter (same IRWIN id, else same
/// name).
///
/// Field names verified live on 2026-09-11 (docs/API_NOTES.md): the incident
/// layer uses plain IRWIN names (`IncidentName`, `IncidentSize`,
/// `PercentContained`, `POOProtectingUnit`); the perimeter layer prefixes
/// polygon fields with `poly_` and the same IRWIN attributes with `attr_`.
/// Both spellings are tried so a rename on either layer degrades gracefully.
List<FireIncident> parseFires({
  Map<String, dynamic>? perimeters,
  Map<String, dynamic>? incidents,
}) {
  final fires = <FireIncident>[];
  final irwinWithPerimeter = <String>{};
  final namesWithPerimeter = <String>{};

  final perimeterFeatures =
      (perimeters?['features'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  for (final f in perimeterFeatures) {
    final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    // The IRWIN name (attr_) is the one InciWeb uses; poly_ is the GIS name.
    final name = displayFireName(
      pickField(props, ['attr_IncidentName', 'IncidentName'])?.toString(),
      pickField(props, ['poly_IncidentName'])?.toString(),
    );
    final rings = ringsFromGeoJson(f['geometry'] as Map<String, dynamic>?);
    final type =
        pickField(props, ['attr_IncidentTypeCategory', 'IncidentTypeCategory'])
            ?.toString();
    final irwin = _irwin(pickField(props, ['poly_IRWINID', 'attr_IrwinID']));
    if (irwin != null) irwinWithPerimeter.add(irwin);
    namesWithPerimeter.add(name.toLowerCase());
    fires.add(
      FireIncident(
        id: 'perim_${f['id'] ?? name}',
        name: name,
        acres: (pickField(props, [
          'poly_GISAcres',
          'GISAcres',
          'attr_IncidentSize',
          'attr_CalculatedAcres',
        ]) as num?)
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
          pickField(props, [
            'attr_ModifiedOnDateTime_dt',
            'poly_DateCurrent',
            'poly_ModifiedOnDateTime_dt',
          ]),
        ),
        behavior: pickField(
                props, ['attr_FireBehaviorGeneral', 'FireBehaviorGeneral'])
            ?.toString(),
        prescribed: type == 'RX',
        polygons: rings,
        unitId:
            pickField(props, ['attr_POOProtectingUnit', 'POOProtectingUnit'])
                ?.toString(),
        irwinId: irwin,
      ),
    );
  }

  final incidentFeatures =
      (incidents?['features'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  for (final f in incidentFeatures) {
    final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = displayFireName(
      pickField(props, ['IncidentName', 'attr_IncidentName'])?.toString(),
      null,
    );
    final irwin = _irwin(pickField(props, ['IrwinID', 'attr_IrwinID']));
    // Skip an incident point whose perimeter is already listed.
    if (irwin != null && irwinWithPerimeter.contains(irwin)) continue;
    if (irwin == null && namesWithPerimeter.contains(name.toLowerCase())) {
      continue;
    }
    final geom = f['geometry'] as Map<String, dynamic>?;
    final coords = geom?['coordinates'];
    double? lat;
    double? lon;
    if (coords is List && coords.length >= 2) {
      lon = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }
    final type =
        pickField(props, ['IncidentTypeCategory', 'attr_IncidentTypeCategory'])
            ?.toString();
    fires.add(
      FireIncident(
        id: 'inc_${f['id'] ?? name}',
        name: name,
        acres: (pickField(props, [
          'IncidentSize',
          'attr_IncidentSize',
          'FinalAcres',
          'attr_DailyAcres',
        ]) as num?)
            ?.toDouble(),
        percentContained:
            (pickField(props, ['PercentContained', 'attr_PercentContained'])
                    as num?)
                ?.round(),
        discoveredAt: _epochMs(pickField(
            props, ['FireDiscoveryDateTime', 'attr_FireDiscoveryDateTime'])),
        modifiedAt: _epochMs(pickField(
            props, ['ModifiedOnDateTime_dt', 'attr_ModifiedOnDateTime_dt'])),
        behavior: pickField(
                props, ['FireBehaviorGeneral', 'attr_FireBehaviorGeneral'])
            ?.toString(),
        prescribed: type == 'RX',
        lat: lat,
        lon: lon,
        unitId:
            pickField(props, ['POOProtectingUnit', 'attr_POOProtectingUnit'])
                ?.toString(),
        irwinId: irwin,
      ),
    );
  }

  return fires;
}

/// The name to show for a fire. IRWIN names are often typed in capitals
/// ("HIGH LAVA") while the GIS perimeter name is cased ("High Lava"), so a
/// shouting IRWIN name yields to a cased [polyName] and otherwise gets title
/// case. Falls back to "Fire" when both are missing.
String displayFireName(String? irwinName, String? polyName) {
  final a = irwinName?.trim() ?? '';
  final b = polyName?.trim() ?? '';
  if (a.isEmpty) return b.isEmpty ? 'Fire' : (_isShouting(b) ? _title(b) : b);
  if (!_isShouting(a)) return a;
  if (b.isNotEmpty && !_isShouting(b)) return b;
  return _title(a);
}

bool _isShouting(String s) =>
    s.contains(RegExp(r'[A-Z]')) && !s.contains(RegExp(r'[a-z]'));

/// "HIGH LAVA" to "High Lava"; short all-caps tokens that read as codes
/// ("RX", "II") keep their case.
String _title(String s) => s
    .split(' ')
    .map((w) => w.length <= 2
        ? w
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

/// IRWIN ids come as "{7A43...}"; compare them without braces or case.
String? _irwin(Object? v) {
  if (v == null) return null;
  final s = v.toString().replaceAll(RegExp(r'[{}]'), '').trim().toUpperCase();
  return s.isEmpty ? null : s;
}
