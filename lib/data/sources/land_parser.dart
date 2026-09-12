// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/worker/geo_worker.dart';
import '../../domain/models/land_unit.dart';
import 'nifc_source.dart' show ringsFromGeoJson;
import 'usfs_source.dart' show pickField;

/// Parses an ArcGIS GeoJSON layer of land polygons (wilderness, forest, park
/// boundaries) into [LandUnit]s, naming each from the first of [nameFields]
/// present. Pure and top-level so it can run on a worker isolate.
List<LandUnit> parseLandUnits(
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

/// [parseLandUnits] on a worker isolate: a forest boundary runs to tens of
/// thousands of vertices, far past the 4 ms UI budget.
Future<List<LandUnit>> parseLandUnitsAsync(
  Map<String, dynamic>? geo,
  LandKind kind,
  List<String> nameFields,
) =>
    GeoWorker.run('land-parse', () => parseLandUnits(geo, kind, nameFields));
