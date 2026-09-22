// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo/contours.dart';
import '../../core/geo/tile_math.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../data/sources/terrain_tile_source.dart';
import 'map_geojson.dart';
import 'map_providers.dart';

/// Fills the style's `cairn-contours` source for a viewport: picks the
/// interval and terrain zoom for the map zoom, traces each terrain tile in
/// view on the worker isolate (cached per tile and interval, so panning
/// re-traces only what is new), and sends one FeatureCollection. Shared by
/// Explore and Navigate through [contourLayerSyncProvider], so both tabs
/// reuse the traced tiles; each map keeps its own last signature since a
/// style reload starts with an empty source.
class ContourLayerSync {
  ContourLayerSync(this._terrain);

  final TerrainTileSource _terrain;

  /// Traced features per tile and interval, most recently used last.
  final _cache = <String, List<Map<String, dynamic>>>{};
  static const _cacheCap = 48;

  /// Sends the contours for [viewport], or clears the source when [spec] is
  /// null (contours off, zoom too wide, or a base map with its own). Returns
  /// the signature of what is now in the source, to pass back as
  /// [previousSig]; null when the view went stale part way and nothing was
  /// sent (keep the old signature).
  Future<String?> sync({
    required MapLibreMapController controller,
    required MapViewport viewport,
    required ContourSpec? spec,
    required String? previousSig,
    required bool Function() isStale,
  }) async {
    if (spec == null) {
      if (previousSig != '') {
        await controller.setGeoJsonSource(
            'cairn-contours', emptyFeatureCollection());
      }
      return '';
    }
    final tiles = tilesForBboxCenterFirst(viewport.bbox, spec.demZoom);
    final sig = '${spec.key}:${tiles.map((t) => t.key).join(',')}';
    if (sig == previousSig) return sig;

    final features = <Map<String, dynamic>>[];
    for (final t in tiles) {
      if (isStale()) return null;
      final traced = await _tileFeatures(t, spec);
      if (traced != null) features.addAll(traced);
    }
    if (isStale()) return null;
    await controller.setGeoJsonSource(
      'cairn-contours',
      {'type': 'FeatureCollection', 'features': features},
    );
    return sig;
  }

  Future<List<Map<String, dynamic>>?> _tileFeatures(
    TileXY t,
    ContourSpec spec,
  ) async {
    final key = '${t.key}/${spec.key}';
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    final main = await _terrain.tile(t);
    if (main == null) return null;
    // The east, south, and southeast neighbors supply the extra column and
    // row, so lines meet across tile seams (see stitchTileGrid).
    final east = await _terrain.tile(TileXY(t.x + 1, t.y, t.z));
    final south = await _terrain.tile(TileXY(t.x, t.y + 1, t.z));
    final southEast = await _terrain.tile(TileXY(t.x + 1, t.y + 1, t.z));
    final grid =
        stitchTileGrid(main, east: east, south: south, southEast: southEast);
    final features = await contourTileAsync(
      grid: grid,
      n: 257,
      tx: t.x,
      ty: t.y,
      tz: t.z,
      spec: spec,
    );
    _cache[key] = features;
    if (_cache.length > _cacheCap) _cache.remove(_cache.keys.first);
    return features;
  }
}

final contourLayerSyncProvider = Provider<ContourLayerSync>(
  (ref) => ContourLayerSync(ref.watch(terrainTileSourceProvider)),
);

/// The contour lines to trace for [viewport] on [basemapKey], or null when
/// they are off, the view is too wide, or the base map draws its own.
ContourSpec? contourSpecForView({
  required MapViewport viewport,
  required bool enabled,
  required String basemapKey,
  required UnitSystem units,
}) {
  if (!enabled || basemapKey == 'topo') return null;
  return contourSpecFor(viewport.zoom, units);
}
