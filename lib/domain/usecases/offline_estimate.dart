// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import '../../core/geo/haversine.dart';
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

/// Bounding boxes (south, west, north, east) covering a route corridor: the
/// route is cut into pieces about [chunkM] long and each piece's box is padded
/// by [bufferM]. A route download fetches these at trail-detail zooms (z15 to
/// z16) on top of the whole-area box at z10 to z14, so junctions are readable
/// without downloading a whole rectangle of high-zoom tiles (docs/DECISIONS.md,
/// route-corridor downloads).
List<List<double>> corridorBoxes(
  List<List<double>> route, {
  double bufferM = 1500,
  double chunkM = 2500,
}) {
  if (route.isEmpty) return const [];
  final boxes = <List<double>>[];
  var minLat = route.first[0], maxLat = route.first[0];
  var minLon = route.first[1], maxLon = route.first[1];
  var run = 0.0;
  void flush() {
    final latPad = bufferM / 111320.0;
    final lonPad =
        bufferM / (111320.0 * math.cos((minLat + maxLat) / 2 * math.pi / 180));
    boxes.add(
        [minLat - latPad, minLon - lonPad, maxLat + latPad, maxLon + lonPad]);
  }

  for (var i = 1; i < route.length; i++) {
    final p = route[i];
    run += haversineMeters(route[i - 1][0], route[i - 1][1], p[0], p[1]);
    minLat = math.min(minLat, p[0]);
    maxLat = math.max(maxLat, p[0]);
    minLon = math.min(minLon, p[1]);
    maxLon = math.max(maxLon, p[1]);
    if (run >= chunkM) {
      flush();
      run = 0;
      minLat = maxLat = p[0];
      minLon = maxLon = p[1];
    }
  }
  flush();
  return boxes;
}

/// Tiles across [boxes] for the zoom range, counting a tile once even when two
/// overlapping corridor boxes share it.
int corridorTileCount(
  List<List<double>> boxes, {
  required int minZoom,
  required int maxZoom,
}) {
  final seen = <String>{};
  for (final b in boxes) {
    for (var z = minZoom; z <= maxZoom; z++) {
      for (final t in tilesForBbox(b, z)) {
        seen.add(t.key);
      }
    }
  }
  return seen.length;
}
