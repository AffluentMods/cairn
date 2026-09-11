// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:cairn/core/geo/tile_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Inverse of latLonToPixel, for the round-trip test.
({double lat, double lon}) pixelToLatLon(TilePixel p) {
  final n = math.pow(2, p.tile.z).toDouble();
  final xf = p.tile.x + p.px / 256.0;
  final yf = p.tile.y + p.py / 256.0;
  final lon = xf / n * 360.0 - 180.0;
  final latRad = math.atan(_sinh(math.pi * (1 - 2 * yf / n)));
  return (lat: latRad * 180.0 / math.pi, lon: lon);
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

void main() {
  test('lat/lon to pixel round trips within 1e-6 degrees', () {
    final rng = math.Random(42);
    for (var i = 0; i < 20; i++) {
      final lat = rng.nextDouble() * 140 - 70; // avoid the poles
      final lon = rng.nextDouble() * 360 - 180;
      final z = 8 + rng.nextInt(9); // z8..z16
      final p = latLonToPixel(lat, lon, z);
      final back = pixelToLatLon(p);
      expect(back.lat, closeTo(lat, 1e-6), reason: 'lat at z$z');
      expect(back.lon, closeTo(lon, 1e-6), reason: 'lon at z$z');
    }
  });

  test('tileBounds contains the coordinate that produced the tile', () {
    const lat = 46.47, lon = -121.45;
    const z = 12;
    final t = latLonToTile(lat, lon, z);
    final b = tileBounds(t); // south, west, north, east
    expect(lat, inInclusiveRange(b[0], b[2]));
    expect(lon, inInclusiveRange(b[1], b[3]));
  });

  test('tilesForBbox covers a small box and every tile is at that zoom', () {
    final tiles = tilesForBbox([46.40, -121.55, 46.55, -121.35], 12);
    expect(tiles, isNotEmpty);
    expect(tiles.every((t) => t.z == 12), isTrue);
    // The box spans a few tiles at z12, not hundreds.
    expect(tiles.length, lessThan(30));
  });

  test('tile key format', () {
    expect(const TileXY(2640, 5787, 14).key, 'z14/2640/5787');
  });
}
