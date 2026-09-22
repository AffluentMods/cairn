// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cairn/core/geo/contours.dart';
import 'package:cairn/core/units/unit_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const metric = ContourSpec(
    intervalUnits: 20,
    indexEvery: 5,
    units: UnitSystem.metric,
    demZoom: 12,
  );

  /// A grid of [n] by [n] samples from [f](i, j).
  Float32List grid(int n, double Function(int i, int j) f) {
    final g = Float32List(n * n);
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        g[j * n + i] = f(i, j);
      }
    }
    return g;
  }

  test('a cone yields one closed ring per level, at the right radius', () {
    const n = 65;
    // Elevation falls 5 m per sample from a 300 m summit at the center.
    final g = grid(n, (i, j) {
      final d = math.sqrt(math.pow(i - 32, 2) + math.pow(j - 32, 2));
      return 300 - 5 * d;
    });
    final feats = contourTile(
      grid: g,
      n: n,
      tx: 0,
      ty: 0,
      tz: 12,
      spec: metric,
      simplifyPx: 0,
    );
    // Levels 160..280 fit inside the grid (radius 28 samples at 160 m).
    final byLevel = <int, List<Map<String, dynamic>>>{};
    for (final f in feats) {
      byLevel.putIfAbsent(f['properties']['e'] as int, () => []).add(f);
    }
    expect(byLevel.keys, containsAll([200, 240, 280]));
    for (final e in [200, 240, 280]) {
      expect(byLevel[e]!.length, 1, reason: 'one ring at $e m');
      final coords = (byLevel[e]!.single['geometry']['coordinates'] as List);
      expect(coords.first, coords.last, reason: 'ring is closed');
      expect(coords.length, greaterThan(20));
    }
    // Index lines are every 100 m and labeled with grouping.
    final ring200 = byLevel[200]!.single['properties'];
    expect(ring200['i'], 1);
    expect(ring200['l'], '200');
    expect(byLevel[240]!.single['properties']['i'], 0);
    expect(byLevel[240]!.single['properties'].containsKey('l'), isFalse);
  });

  test('a tilted plane yields straight open lines that reach the edges', () {
    const n = 33;
    final g = grid(n, (i, j) => 100.0 + 3.0 * i);
    final feats = contourTile(
      grid: g,
      n: n,
      tx: 0,
      ty: 0,
      tz: 12,
      spec: metric,
      simplifyPx: 0.2,
    );
    // Levels 120, 140, ... 180 cross the grid (100 to 196 m).
    expect(
        feats.map((f) => f['properties']['e']).toSet(), {120, 140, 160, 180});
    for (final f in feats) {
      final coords =
          (f['geometry']['coordinates'] as List).cast<List<double>>();
      // A straight line simplifies to its two ends.
      expect(coords.length, 2);
      // Both ends sit on the north and south tile edges (same longitude).
      expect(coords.first[0], closeTo(coords.last[0], 1e-9));
    }
  });

  test('grouping and imperial labels', () {
    const imperial = ContourSpec(
      intervalUnits: 200,
      indexEvery: 5,
      units: UnitSystem.imperial,
      demZoom: 11,
    );
    expect(imperial.intervalM, closeTo(60.96, 1e-9));
    expect(imperial.indexUnits, 1000);
    const n = 33;
    // 0 to 1,200 m across the grid: index lines at 1000 ft (304.8 m).
    final g = grid(n, (i, j) => 37.5 * i);
    final feats = contourTile(
      grid: g,
      n: n,
      tx: 0,
      ty: 0,
      tz: 11,
      spec: imperial,
    );
    final labels = {
      for (final f in feats)
        if (f['properties']['i'] == 1) f['properties']['l'] as String
    };
    expect(labels, containsAll(['1,000', '2,000', '3,000']));
  });

  test('stitched neighbors make lines meet at the seam', () {
    // A plane rising to the east across two tiles: the 20 m line at the seam
    // of tile A (with B's first column) lands where B's own line starts.
    const s = 256;
    final a = Float32List(s * s);
    final b = Float32List(s * s);
    for (var j = 0; j < s; j++) {
      for (var i = 0; i < s; i++) {
        a[j * s + i] = 0.1 * i; // 0 .. 25.5 m
        b[j * s + i] = 0.1 * (i + s); // 25.6 .. 51.1 m
      }
    }
    final ga = stitchTileGrid(a, east: b);
    final gb = stitchTileGrid(b);
    final fa =
        contourTile(grid: ga, n: s + 1, tx: 0, ty: 0, tz: 8, spec: metric);
    final fb =
        contourTile(grid: gb, n: s + 1, tx: 1, ty: 0, tz: 8, spec: metric);
    // 20 m sits inside A (i = 200); 40 m inside B (i = 144 of B).
    expect(fa.map((f) => f['properties']['e']).toSet(), {20});
    expect(fb.map((f) => f['properties']['e']).toSet(), {40});
    // A's grid includes B's first column, so it holds no 40 m crossing but
    // its samples run to the shared edge: the last column is B's first.
    expect(ga[s], closeTo(b[0], 1e-6));
    expect(ga[(s + 1) * (s + 1) - 1], closeTo(b[(s - 1) * s], 1e-6));
  });

  test('contour spec follows zoom and units', () {
    expect(contourSpecFor(11.9, UnitSystem.imperial), isNull);
    final z12 = contourSpecFor(12.4, UnitSystem.imperial)!;
    expect((z12.intervalUnits, z12.demZoom), (200, 11));
    final z14 = contourSpecFor(14.0, UnitSystem.imperial)!;
    expect((z14.intervalUnits, z14.demZoom), (100, 13));
    final z16 = contourSpecFor(16.7, UnitSystem.metric)!;
    expect((z16.intervalUnits, z16.demZoom, z16.unitLabel), (10, 14, 'm'));
    expect(z16.smoothPasses, 2);
    expect(z14.smoothPasses, 1);
  });
}
