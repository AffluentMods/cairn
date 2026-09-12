// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../core/geo/terrarium.dart';
import '../../core/geo/tile_math.dart';

/// Elevation lookups from the decoded `.f32` sidecars that
/// `TerrainTileSource` writes next to each cached terrarium PNG. No PNG
/// decoding and no network, so it runs in the foreground task isolate during
/// a recording: a tile is either on disk from planning the route (or an
/// offline region) or it is not, and the engine falls back to GPS altitude.
class TerrainSidecarReader {
  TerrainSidecarReader(this.terrainDir, {this.zoom = 14, this.maxTiles = 12});

  final Directory terrainDir;
  final int zoom;
  final int maxTiles;

  // Insertion-ordered so the oldest entry is the LRU victim.
  final _cache = <String, Float32List>{};

  static const _gridLen = 256 * 256;

  /// Sidecar path for a terrarium tile at [pngPath].
  static String sidecarPathFor(String pngPath) =>
      '${p.withoutExtension(pngPath)}.f32';

  /// Writes a decoded grid next to its PNG. Best effort: a failure only means
  /// the recording engine will use GPS altitude for that tile.
  static Future<void> writeSidecar(String pngPath, Float32List grid) async {
    try {
      final f = File(sidecarPathFor(pngPath));
      await f.parent.create(recursive: true);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsBytes(
        grid.buffer.asUint8List(grid.offsetInBytes, grid.lengthInBytes),
        flush: true,
      );
      await tmp.rename(f.path);
    } on FileSystemException {
      // ignore
    }
  }

  File _fileFor(TileXY t) => File(
        p.join(terrainDir.path, '${t.z}', '${t.x}', '${t.y}.f32'),
      );

  Float32List? _grid(TileXY t) {
    final hit = _cache.remove(t.key);
    if (hit != null) {
      _cache[t.key] = hit; // refresh recency
      return hit;
    }
    final f = _fileFor(t);
    if (!f.existsSync()) return null;
    final bytes = f.readAsBytesSync();
    if (bytes.length != _gridLen * 4) return null;
    // Copy into an aligned buffer: a view over the file bytes may not be
    // 4-byte aligned.
    final grid = Float32List(_gridLen);
    grid.buffer.asUint8List().setAll(0, bytes);
    _cache[t.key] = grid;
    if (_cache.length > maxTiles) _cache.remove(_cache.keys.first);
    return grid;
  }

  /// Elevation in meters, or null when the tile has no sidecar.
  double? elevationAt(double lat, double lon) {
    final px = latLonToPixel(lat, lon, zoom);
    final grid = _grid(px.tile);
    if (grid == null) return null;
    return bilinearSample(grid, 256, 256, px.px, px.py);
  }
}
