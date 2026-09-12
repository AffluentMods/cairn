// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/tile_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tilesForBboxCenterFirst puts the center cell first', () {
    // A 3 by 3 block of z10 cells around Goat Rocks.
    const bbox = [46.0, -122.2, 47.0, -120.8];
    final all = tilesForBbox(bbox, 10);
    final ordered = tilesForBboxCenterFirst(bbox, 10);
    expect(ordered.length, all.length);
    expect(ordered.toSet(), all.toSet());
    final center = latLonToTile(46.5, -121.5, 10);
    expect(ordered.first, center);
    // Distance from the (fractional) bbox center never decreases.
    final c = latLonToPixel(46.5, -121.5, 10);
    final cx = c.tile.x + c.px / 256;
    final cy = c.tile.y + c.py / 256;
    double d(TileXY t) {
      final dx = t.x + 0.5 - cx;
      final dy = t.y + 0.5 - cy;
      return dx * dx + dy * dy;
    }

    for (var i = 1; i < ordered.length; i++) {
      expect(d(ordered[i]), greaterThanOrEqualTo(d(ordered[i - 1])));
    }
    expect(d(ordered.last), greaterThan(d(ordered.first)));
  });

  test('a single cell is returned as is', () {
    const bbox = [46.46, -121.47, 46.49, -121.44];
    expect(tilesForBboxCenterFirst(bbox, 10).length, 1);
  });
}
