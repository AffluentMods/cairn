// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/trail.dart';
import '../../domain/repositories/trail_repository.dart';
import 'map_geojson.dart';
import 'map_providers.dart';

/// The most z10 cells one viewport may fetch from Overpass (a 2 by 2 block,
/// roughly zoom 10 and closer on a phone). Wider views render cached trails.
const maxCellsPerRefresh = 4;

/// True when [viewport] is close enough to fetch missing cells for.
bool viewportFetchesCells(MapViewport viewport) =>
    tilesForBbox(viewport.bbox, 10).length <= maxCellsPerRefresh;

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
/// rendering), shared by Explore and Navigate: fetches missing cells when
/// [fetch] is set (center first, stopping once [isStale] reports the view
/// moved on), reads the cached ways, and sends a new FeatureCollection only
/// when the set differs from [previousSig] (Fix Pass 1 X1.3.4). Returns null
/// when the view went stale part way, so the caller skips its follow-ups.
Future<TrailsLayerResult?> syncTrailsLayer({
  required MapLibreMapController controller,
  required MapViewport viewport,
  required TrailRepository repo,
  required int? previousSig,
  required bool Function() isStale,
  bool fetch = true,
}) async {
  final load = fetch
      ? await repo.ensureArea(viewport.bbox, isCancelled: isStale)
      : const TrailLoadResult(networkError: false, cellsFetched: 0);
  if (isStale()) return null;
  final trails = await repo.trailsInBbox(viewport.bbox);
  if (isStale()) return null;
  final sig = trailsSignature(trails, viewport.zoom);
  if (sig != previousSig) {
    final geojson = await trailsToGeoJsonAsync(trails, zoom: viewport.zoom);
    if (isStale()) return null;
    await controller.setGeoJsonSource('cairn-trails', geojson);
  }
  return TrailsLayerResult(sig: sig, load: load, trails: trails);
}
