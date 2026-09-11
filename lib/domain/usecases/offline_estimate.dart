// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/tile_math.dart';

/// The estimated download size for an offline region (spec Phase 5).
class RegionEstimate {
  const RegionEstimate({required this.tileCount, required this.bytes});
  final int tileCount;
  final int bytes;

  bool get isLarge => bytes > 1024 * 1024 * 1024; // over 1 GB
}

// Rough per-tile sizes (spec Phase 5).
const _vectorTileBytes = 25 * 1024;
const _rasterTileBytes = 60 * 1024;
const _terrainTileBytes = 30 * 1024;
const _terrainZoom = 14;

/// Estimates the bytes to download for a bbox: basemap tiles across the zoom
/// range for each selected style (vector for Outdoors, raster for Topo and
/// Satellite), plus one set of terrain tiles at z14.
RegionEstimate estimateRegionBytes(
  List<double> bbox, {
  required int minZoom,
  required int maxZoom,
  int vectorStyles = 0,
  int rasterStyles = 0,
}) {
  var vectorTiles = 0;
  var rasterTiles = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final n = tilesForBbox(bbox, z).length;
    vectorTiles += n * vectorStyles;
    rasterTiles += n * rasterStyles;
  }
  final terrainTiles = tilesForBbox(bbox, _terrainZoom).length;
  final bytes = vectorTiles * _vectorTileBytes +
      rasterTiles * _rasterTileBytes +
      terrainTiles * _terrainTileBytes;
  return RegionEstimate(
    tileCount: vectorTiles + rasterTiles + terrainTiles,
    bytes: bytes,
  );
}
