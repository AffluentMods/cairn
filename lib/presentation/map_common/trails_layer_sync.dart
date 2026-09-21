// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/trail.dart';
import '../../domain/repositories/trail_repository.dart';
import 'map_geojson.dart';
import 'map_providers.dart';

/// The most z10 cells one viewport may fetch trails for: a 4 by 4 block,
/// about zoom 9 on a phone. Cells load center first and paint one by one, so
/// the nearest trails show within a query or two while the rest fill in.
/// Wider views draw what is cached and the list says to zoom in.
const maxTrailCellsPerRefresh = 16;

/// POIs stay on the closer 2 by 2 budget: at wider zooms their icons would
/// only collide, and the trail pass already spends the Overpass time.
const maxPoiCellsPerRefresh = 4;

/// How many z10 cells [viewport] covers.
int viewportCellCount(MapViewport viewport) =>
    tilesForBbox(viewport.bbox, 10).length;

/// True when [viewport] is close enough to fetch missing cells for.
bool viewportFetchesCells(
  MapViewport viewport, {
  int maxCells = maxTrailCellsPerRefresh,
}) =>
    viewportCellCount(viewport) <= maxCells;

/// Below this zoom only named ways render (see `trailsToGeoJson`), so the
/// database read asks for named ways only and a wide view is not cut short
/// by thousands of unnamed connectors it would discard anyway.
const namedOnlyBelowZoom = 11.0;

/// What one trails refresh produced.
class TrailsLayerResult {
  const TrailsLayerResult({
    required this.sig,
    required this.load,
    required this.trails,
  });

  /// Signature of the set now in the source; pass back as `previousSig`.
  final int sig;
  final TrailLoadResult load;
  final List<Trail> trails;
}

/// Fills the style's `cairn-trails` source for [viewport] (spec Phase 2
/// rendering), shared by Explore and Navigate. Paints the cached ways first,
/// then, when [fetch] is set, fetches missing cells center first and repaints
/// after each one that arrives, so trails appear cell by cell instead of after
/// the whole pass. [onProgress] reports each cell (done, total, fetched); the
/// pass stops once [isStale] reports the view moved on. A new FeatureCollection
/// is sent only when the set differs from the last one sent (Fix Pass 1
/// X1.3.4). Returns null when the view went stale part way, so the caller skips
/// its follow-ups.
Future<TrailsLayerResult?> syncTrailsLayer({
  required MapLibreMapController controller,
  required MapViewport viewport,
  required TrailRepository repo,
  required int? previousSig,
  required bool Function() isStale,
  bool fetch = true,
  TrailCellProgress? onProgress,
}) async {
  var sig = previousSig;
  var trails = const <Trail>[];

  /// Reads the cached ways for the view and sends them if the set changed.
  /// False when the view went stale while it worked.
  Future<bool> paint() async {
    final read = await repo.trailsInBbox(
      viewport.bbox,
      namedOnly: viewport.zoom < namedOnlyBelowZoom,
    );
    if (isStale()) return false;
    trails = read;
    final next = trailsSignature(read, viewport.zoom);
    if (next != sig) {
      final geojson = await trailsToGeoJsonAsync(read, zoom: viewport.zoom);
      if (isStale()) return false;
      await controller.setGeoJsonSource('cairn-trails', geojson);
      sig = next;
    }
    return true;
  }

  if (!await paint()) return null;
  var load = const TrailLoadResult(networkError: false, cellsFetched: 0);
  if (fetch) {
    var stale = false;
    load = await repo.ensureArea(
      viewport.bbox,
      isCancelled: isStale,
      onCell: (done, total, fetched) async {
        if (stale) return;
        if (fetched && !await paint()) {
          stale = true;
          return;
        }
        await onProgress?.call(done, total, fetched);
      },
    );
    if (stale || isStale()) return null;
  }
  return TrailsLayerResult(sig: sig!, load: load, trails: trails);
}
