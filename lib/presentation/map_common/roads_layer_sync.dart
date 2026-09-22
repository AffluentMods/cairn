// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo/polyline_simplify.dart';
import '../../core/worker/geo_worker.dart';
import '../../domain/models/forest_road.dart';
import '../../domain/repositories/road_repository.dart';
import 'map_geojson.dart';
import 'map_providers.dart';
import 'trails_layer_sync.dart';

/// The line layers the forest roads source draws, for tap queries.
const roadLayerIds = [
  'roads',
  'roads-seasonal',
  'roads-trails',
  'roads-trails-seasonal',
];

/// Fills the style's `cairn-roads` source for [viewport] (Forest Service
/// MVUM roads and motorized trails), shared by Explore and Navigate. Fetches
/// missing cells when the view is close enough (the POI budget: a 2 by 2
/// block), reads the cache, and sends a new FeatureCollection only when the
/// set differs from [previousSig]. Returns the signature now in the source,
/// or null when the view went stale part way.
Future<int?> syncRoadsLayer({
  required MapLibreMapController controller,
  required MapViewport viewport,
  required RoadRepository repo,
  required int? previousSig,
  required bool Function() isStale,
}) async {
  if (viewportFetchesCells(viewport, maxCells: maxPoiCellsPerRefresh)) {
    await repo.ensureArea(viewport.bbox, isCancelled: isStale);
  }
  if (isStale()) return null;
  final roads = await repo.roadsInBbox(viewport.bbox);
  if (isStale()) return null;
  final sig = roadsSignature(roads, viewport.zoom);
  if (sig != previousSig) {
    final geojson = await roadsToGeoJsonAsync(roads, zoom: viewport.zoom);
    if (isStale()) return null;
    await controller.setGeoJsonSource('cairn-roads', geojson);
  }
  return sig;
}

/// FNV-1a over the segment ids plus the simplification bucket, so an
/// unchanged set is not rebuilt and re-sent.
int roadsSignature(List<ForestRoad> roads, double zoom) {
  var hash = 0x811c9dc5;
  hash = (hash ^ _bucket(zoom)) * 0x01000193 & 0xFFFFFFFF;
  for (final r in roads) {
    final id = r.id.hashCode;
    hash = (hash ^ (id & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
    hash = (hash ^ ((id >> 16) & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
  }
  return hash;
}

int _bucket(double zoom) => zoom < 12 ? 0 : (zoom < 14 ? 1 : 2);

/// [roadsToGeoJson] on a worker isolate.
Future<Map<String, dynamic>> roadsToGeoJsonAsync(
  List<ForestRoad> roads, {
  required double zoom,
}) =>
    GeoWorker.run('roads-geojson', () => roadsToGeoJson(roads, zoom: zoom));

/// Forest road segments as LineString features with the properties the style
/// filters and labels on: `id`, `number`, `kind` (road or trail), `seasonal`
/// (0 or 1), and `cls` (the MVUM symbol class). Lines are simplified at wide
/// zooms, like trails.
Map<String, dynamic> roadsToGeoJson(
  List<ForestRoad> roads, {
  required double zoom,
}) {
  final tolerance = switch (_bucket(zoom)) { 0 => 30.0, 1 => 8.0, _ => 0.0 };
  final features = <Map<String, dynamic>>[];
  for (final r in roads) {
    final geom = tolerance == 0
        ? r.geometry
        : simplifyDouglasPeucker(r.geometry, tolerance);
    if (geom.length < 2) continue;
    features.add({
      'type': 'Feature',
      'properties': {
        'id': r.id,
        'number': r.number,
        'kind': r.kind,
        'seasonal': r.seasonal ? 1 : 0,
        'cls': r.symbol,
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          for (final p in geom) [p[1], p[0]],
        ],
      },
    });
    if (features.length >= maxTrailFeatures) break;
  }
  return {'type': 'FeatureCollection', 'features': features};
}
