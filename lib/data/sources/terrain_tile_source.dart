// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../core/geo/terrarium.dart';
import '../../core/geo/tile_math.dart';

/// Fetches terrarium elevation PNG tiles at a fixed zoom and caches them on disk
/// (spec Sections 5.1, 8.3). Decodes each tile to a Float32List of meters once,
/// so repeated lookups do not re-decode. Works offline for cached tiles, which
/// is what makes offline elevation profiles possible.
class TerrainTileSource {
  TerrainTileSource(this._dio, this._cacheDir);

  static const zoom = 14;
  static const _tileUrl =
      'https://s3.amazonaws.com/elevation-tiles-prod/terrarium';

  final Dio _dio;
  final Directory _cacheDir;
  final _memory = <String, Float32List>{};

  File _fileFor(TileXY t) =>
      File(p.join(_cacheDir.path, 'terrain', '${t.z}', '${t.x}', '${t.y}.png'));

  /// Decoded elevation grid for a tile (256x256, row-major, meters), or null if
  /// it is neither cached nor reachable.
  Future<Float32List?> tile(TileXY t) async {
    final cached = _memory[t.key];
    if (cached != null) return cached;

    final file = _fileFor(t);
    Uint8List? bytes;
    if (file.existsSync()) {
      bytes = await file.readAsBytes();
    } else {
      bytes = await _download(t, file);
    }
    if (bytes == null) return null;

    final grid = _decode(bytes);
    if (grid != null) _memory[t.key] = grid;
    return grid;
  }

  Future<Uint8List?> _download(TileXY t, File file) async {
    try {
      final res = await _dio.get<List<int>>(
        '$_tileUrl/${t.z}/${t.x}/${t.y}.png',
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final bytes = Uint8List.fromList(res.data!);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return bytes;
    } on DioException {
      return null; // offline: caller degrades to GPS altitude
    }
  }

  Float32List? _decode(Uint8List bytes) {
    final image = img.decodePng(bytes);
    if (image == null || image.width != 256 || image.height != 256) return null;
    final grid = Float32List(256 * 256);
    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        final pixel = image.getPixel(x, y);
        grid[y * 256 + x] = terrariumToMeters(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
      }
    }
    return grid;
  }

  /// Elevation in meters at a coordinate, or null when the tile is unavailable.
  Future<double?> elevationAt(double lat, double lon) async {
    final pixel = latLonToPixel(lat, lon, zoom);
    final grid = await tile(pixel.tile);
    if (grid == null) return null;
    return bilinearSample(grid, 256, 256, pixel.px, pixel.py);
  }

  /// Batched elevations for many coordinates, grouping by tile so a long route
  /// touches a handful of tiles rather than thousands of lookups. Missing tiles
  /// yield null at those indices.
  Future<List<double?>> elevations(List<List<double>> latLon) async {
    final result = List<double?>.filled(latLon.length, null);
    final byTile = <String, List<int>>{};
    final tileOf = <String, TileXY>{};
    for (var i = 0; i < latLon.length; i++) {
      final t = latLonToTile(latLon[i][0], latLon[i][1], zoom);
      byTile.putIfAbsent(t.key, () => []).add(i);
      tileOf[t.key] = t;
    }
    for (final entry in byTile.entries) {
      final grid = await tile(tileOf[entry.key]!);
      if (grid == null) continue;
      for (final i in entry.value) {
        final px = latLonToPixel(latLon[i][0], latLon[i][1], zoom);
        result[i] = bilinearSample(grid, 256, 256, px.px, px.py);
      }
    }
    return result;
  }
}
