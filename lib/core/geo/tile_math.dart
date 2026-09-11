// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// A slippy-map tile coordinate (spec Section 8, Phase 2).
class TileXY {
  const TileXY(this.x, this.y, this.z);
  final int x;
  final int y;
  final int z;

  String get key => 'z$z/$x/$y';

  @override
  bool operator ==(Object other) =>
      other is TileXY && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => key;
}

/// Fractional pixel position of a coordinate inside a 256 px tile.
class TilePixel {
  const TilePixel(this.tile, this.px, this.py);
  final TileXY tile;
  final double px;
  final double py;
}

TileXY latLonToTile(double lat, double lon, int z) {
  final n = math.pow(2, z).toDouble();
  final x = ((lon + 180) / 360 * n).floor();
  final latRad = lat * math.pi / 180;
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
          2 *
          n)
      .floor();
  return TileXY(x, y, z);
}

/// Returns (south, west, north, east) for a tile.
List<double> tileBounds(TileXY t) {
  final n = math.pow(2, t.z).toDouble();
  double lonOf(int x) => x / n * 360 - 180;
  double latOf(int y) {
    final a = math.pi - 2 * math.pi * y / n;
    return 180 / math.pi * math.atan(0.5 * (math.exp(a) - math.exp(-a)));
  }

  return [latOf(t.y + 1), lonOf(t.x), latOf(t.y), lonOf(t.x + 1)];
}

/// Fractional pixel position of a coordinate inside a 256 px tile at zoom z.
TilePixel latLonToPixel(double lat, double lon, int z) {
  final n = math.pow(2, z).toDouble();
  final xf = (lon + 180) / 360 * n;
  final latRad = lat * math.pi / 180;
  final yf =
      (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
  final tile = TileXY(xf.floor(), yf.floor(), z);
  return TilePixel(tile, (xf - tile.x) * 256, (yf - tile.y) * 256);
}

/// All tiles at zoom [z] covering the bounding box (south, west, north, east).
List<TileXY> tilesForBbox(List<double> bbox, int z) {
  final sw = latLonToTile(bbox[0], bbox[1], z);
  final ne = latLonToTile(bbox[2], bbox[3], z);
  final minX = math.min(sw.x, ne.x);
  final maxX = math.max(sw.x, ne.x);
  // Note: y grows southward, so the north edge has the smaller y.
  final minY = math.min(sw.y, ne.y);
  final maxY = math.max(sw.y, ne.y);
  final out = <TileXY>[];
  for (var x = minX; x <= maxX; x++) {
    for (var y = minY; y <= maxY; y++) {
      out.add(TileXY(x, y, z));
    }
  }
  return out;
}
