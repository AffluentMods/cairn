// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/geo/terrarium.dart';
import '../../core/geo/tile_math.dart';
import 'terrain_sidecar.dart';

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

  /// Decoded grids, most recently used last. Each is 256 KB; the cap keeps the
  /// elevation lookups and the contour tiles of a wide view (a few zooms at
  /// once) resident without growing for as long as the app runs.
  final _memory = <String, Float32List>{};
  static const _memoryCap = 96;

  File _fileFor(TileXY t) =>
      File(p.join(_cacheDir.path, 'terrain', '${t.z}', '${t.x}', '${t.y}.png'));

  /// True when the tile is on disk, so a caller can tell offline coverage
  /// without triggering a download.
  bool isCached(TileXY t) =>
      _memory.containsKey(t.key) || _fileFor(t).existsSync();

  /// Decoded elevation grid for a tile (256x256, row-major, meters), or null if
  /// it is neither cached nor reachable.
  Future<Float32List?> tile(TileXY t) async {
    final cached = _memory.remove(t.key);
    if (cached != null) {
      _memory[t.key] = cached; // back to the most recent end
      return cached;
    }

    final file = _fileFor(t);
    Uint8List? bytes;
    if (file.existsSync()) {
      bytes = await file.readAsBytes();
    } else {
      bytes = await _download(t, file);
    }
    if (bytes == null) return null;

    final grid = await _decode(bytes);
    if (grid != null) {
      _memory[t.key] = grid;
      if (_memory.length > _memoryCap) _memory.remove(_memory.keys.first);
      // A decoded `.f32` sidecar next to the PNG lets the recording service
      // (a separate isolate with no image codec) read DEM elevations for live
      // gain without decoding anything (spec Phase 6).
      final sidecar = File(TerrainSidecarReader.sidecarPathFor(file.path));
      if (!sidecar.existsSync()) {
        unawaited(TerrainSidecarReader.writeSidecar(file.path, grid));
      }
    }
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

  /// Decodes a terrarium PNG to a Float32 meters grid. The PNG is decoded by
  /// the engine (`ui.instantiateImageCodec`, off the UI isolate) rather than
  /// package:image on the UI isolate, and the RGBA to meters conversion (a
  /// 65,536 element loop) runs in a worker isolate. This keeps the whole decode
  /// off the UI isolate (Fix Pass 1 X1.3.1, hypothesis H1).
  Future<Float32List?> _decode(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      if (image.width != 256 || image.height != 256) return null;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return null;
      final pixels = rgba.buffer.asUint8List();
      return await Isolate.run(() => _rgbaToMeters(pixels));
    } on Exception {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  /// Converts a 256x256 RGBA buffer to a row-major Float32 meters grid. Static
  /// and pure so it can run in a worker isolate.
  static Float32List _rgbaToMeters(Uint8List rgba) {
    final grid = Float32List(256 * 256);
    for (var i = 0; i < 256 * 256; i++) {
      final o = i * 4;
      grid[i] = terrariumToMeters(rgba[o], rgba[o + 1], rgba[o + 2]);
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
