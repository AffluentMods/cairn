// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import '../units/unit_formatter.dart';
import '../worker/geo_worker.dart';

/// Which contour lines to draw at a map zoom: the interval and the heavier
/// "index" line, in the user's units, and the terrain tile zoom to derive them
/// from (docs/DECISIONS.md, contours on the device).
class ContourSpec {
  const ContourSpec({
    required this.intervalUnits,
    required this.indexEvery,
    required this.units,
    required this.demZoom,
    this.smoothPasses = 1,
  });

  /// The interval in display units (feet or meters).
  final int intervalUnits;

  /// Every [indexEvery]th line is an index line: heavier, and labeled.
  final int indexEvery;
  final UnitSystem units;

  /// The terrain tile zoom the lines are traced from.
  final int demZoom;

  /// Corner-cutting passes. Two when the map is zoomed well past the terrain
  /// grid (a cell spans several screen pixels), so lines stay rounded.
  final int smoothPasses;

  double get _unitM => units == UnitSystem.imperial ? 0.3048 : 1.0;

  /// The interval in meters.
  double get intervalM => intervalUnits * _unitM;

  String get unitLabel => units == UnitSystem.imperial ? 'ft' : 'm';

  /// The interval of the index lines in display units.
  int get indexUnits => intervalUnits * indexEvery;

  /// Cache key part: the same lines result from the same interval, units,
  /// and smoothing.
  String get key => '${units.name}$intervalUnits/$smoothPasses';
}

/// The contour lines for a map zoom, or null below zoom 12 where hillshade
/// carries the relief on its own. Intervals follow paper maps: 200 ft at the
/// 1:100,000 zooms, 100 ft at 1:50,000, the USGS quad's 40 ft close in;
/// metric 50, 20, and 10 m. The terrain zoom is one below the map zoom, so a
/// grid cell is about two screen pixels, capped at 14 where the source data's
/// resolution ends.
ContourSpec? contourSpecFor(double zoom, UnitSystem units) {
  if (zoom < 12) return null;
  final imperial = units == UnitSystem.imperial;
  final demZoom = (zoom.floor() - 1).clamp(11, 14);
  final passes = zoom >= demZoom + 2 ? 2 : 1;
  if (zoom < 13) {
    return ContourSpec(
      intervalUnits: imperial ? 200 : 50,
      indexEvery: 5,
      units: units,
      demZoom: demZoom,
      smoothPasses: passes,
    );
  }
  if (zoom < 15.5) {
    return ContourSpec(
      intervalUnits: imperial ? 100 : 20,
      indexEvery: 5,
      units: units,
      demZoom: demZoom,
      smoothPasses: passes,
    );
  }
  return ContourSpec(
    intervalUnits: imperial ? 40 : 10,
    indexEvery: 5,
    units: units,
    demZoom: demZoom,
    smoothPasses: passes,
  );
}

/// [contourTile] on a worker isolate. Top-level so the closure captures only
/// plain data (see GeoWorker).
Future<List<Map<String, dynamic>>> contourTileAsync({
  required Float32List grid,
  required int n,
  required int tx,
  required int ty,
  required int tz,
  required ContourSpec spec,
}) =>
    GeoWorker.run(
      'contours',
      () => contourTile(grid: grid, n: n, tx: tx, ty: ty, tz: tz, spec: spec),
    );

/// Contour lines for one terrain tile as GeoJSON LineString features.
///
/// [grid] is an [n] by [n] row-major elevation grid in meters: the tile's own
/// 256 by 256 samples plus one extra column and row taken from the tiles to
/// the east and south, so lines run to the tile edge and meet the neighbor's
/// lines exactly (both tiles trace the shared samples). Each feature carries
/// `e`, the elevation in display units, `i`, 1 for an index line, and `l`,
/// the label text.
///
/// Marching squares, walked once per cell for every level the cell's four
/// corners straddle, so cost scales with the lines drawn rather than with
/// cells times levels. Crossings are keyed by the grid edge they sit on, so
/// segments from neighboring cells chain into one line with no float
/// comparisons. Lines are then rounded with one corner-cutting pass and
/// simplified to about half a grid cell, which keeps the GeoJSON small.
List<Map<String, dynamic>> contourTile({
  required Float32List grid,
  required int n,
  required int tx,
  required int ty,
  required int tz,
  required ContourSpec spec,
  double simplifyPx = 0.45,
}) {
  final interval = spec.intervalM;
  // Segments per level index k: a flat list of edge id pairs.
  final segments = <int, List<int>>{};

  int hEdge(int i, int j) => 2 * (j * n + i);
  int vEdge(int i, int j) => 2 * (j * n + i) + 1;

  void add(int k, int a, int b) {
    (segments[k] ??= <int>[])
      ..add(a)
      ..add(b);
  }

  for (var j = 0; j < n - 1; j++) {
    final row = j * n;
    for (var i = 0; i < n - 1; i++) {
      final a = grid[row + i];
      final b = grid[row + i + 1];
      final c = grid[row + n + i + 1];
      final d = grid[row + n + i];
      var lo = a, hi = a;
      if (b < lo) lo = b;
      if (b > hi) hi = b;
      if (c < lo) lo = c;
      if (c > hi) hi = c;
      if (d < lo) lo = d;
      if (d > hi) hi = d;
      if (hi - lo < 1e-6) continue;
      // Levels strictly above the lowest corner and at most the highest one,
      // so every listed level crosses this cell.
      final kFirst = (lo / interval).floor() + 1;
      final kLast = (hi / interval).floor();
      if (kLast < kFirst) continue;
      final top = hEdge(i, j);
      final right = vEdge(i + 1, j);
      final bottom = hEdge(i, j + 1);
      final left = vEdge(i, j);
      for (var k = kFirst; k <= kLast; k++) {
        final level = k * interval;
        var code = 0;
        if (a >= level) code |= 8;
        if (b >= level) code |= 4;
        if (c >= level) code |= 2;
        if (d >= level) code |= 1;
        switch (code) {
          case 1 || 14:
            add(k, left, bottom);
          case 2 || 13:
            add(k, bottom, right);
          case 3 || 12:
            add(k, left, right);
          case 4 || 11:
            add(k, top, right);
          case 6 || 9:
            add(k, top, bottom);
          case 7 || 8:
            add(k, top, left);
          case 5:
            // b and d above. The center decides which pair connects.
            if ((a + b + c + d) / 4 >= level) {
              add(k, top, left);
              add(k, right, bottom);
            } else {
              add(k, top, right);
              add(k, left, bottom);
            }
          case 10:
            // a and c above.
            if ((a + b + c + d) / 4 >= level) {
              add(k, top, right);
              add(k, left, bottom);
            } else {
              add(k, top, left);
              add(k, right, bottom);
            }
        }
      }
    }
  }

  // Where a level crosses an edge, in sample coordinates.
  List<double> pointOn(int edge, double level) {
    final cell = edge >> 1;
    final j = cell ~/ n;
    final i = cell - j * n;
    final v0 = grid[j * n + i];
    if (edge & 1 == 0) {
      final v1 = grid[j * n + i + 1];
      final t = v1 == v0 ? 0.5 : ((level - v0) / (v1 - v0)).clamp(0.0, 1.0);
      return [i + t, j.toDouble()];
    }
    final v1 = grid[(j + 1) * n + i];
    final t = v1 == v0 ? 0.5 : ((level - v0) / (v1 - v0)).clamp(0.0, 1.0);
    return [i.toDouble(), j + t];
  }

  final features = <Map<String, dynamic>>[];
  final scale = math.pow(2, tz).toDouble();
  final levels = segments.keys.toList()..sort();
  for (final k in levels) {
    final level = k * interval;
    final lines = _chain(segments[k]!);
    final labelValue = k * spec.intervalUnits;
    final isIndex = k % spec.indexEvery == 0;
    final label = _grouped(labelValue);
    for (final edges in lines) {
      var pts = [for (final e in edges) pointOn(e, level)];
      final closed = edges.length > 2 && edges.first == edges.last;
      for (var pass = 0; pass < spec.smoothPasses; pass++) {
        pts = _chaikin(pts, closed);
      }
      pts = simplifyPixels(pts, simplifyPx / spec.smoothPasses);
      // A line needs two distinct points, or MapLibre logs an invalid
      // geometry and skips the whole batch's bucket.
      if (pts.length < 2 ||
          (pts.length == 2 &&
              (pts[0][0] - pts[1][0]).abs() < 1e-9 &&
              (pts[0][1] - pts[1][1]).abs() < 1e-9)) {
        continue;
      }
      final coords = <List<double>>[];
      for (final p in pts) {
        // Sample (i, j) sits at the pixel center (i + 0.5, j + 0.5).
        final px = (tx + (p[0] + 0.5) / 256) / scale;
        final py = (ty + (p[1] + 0.5) / 256) / scale;
        final lon = px * 360 - 180;
        final lat = math.atan(_sinh(math.pi * (1 - 2 * py))) * 180 / math.pi;
        coords.add([_round6(lon), _round6(lat)]);
      }
      features.add({
        'type': 'Feature',
        'properties': {
          'e': labelValue,
          'i': isIndex ? 1 : 0,
          if (isIndex) 'l': label,
        },
        'geometry': {'type': 'LineString', 'coordinates': coords},
      });
    }
  }
  return features;
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

double _round6(double v) => (v * 1e6).round() / 1e6;

String _grouped(int v) {
  final s = v.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return v < 0 ? '-$out' : out.toString();
}

/// Joins edge-id segment pairs into polylines of edge ids. A closed ring
/// repeats its first edge at the end.
List<List<int>> _chain(List<int> pairs) {
  final count = pairs.length ~/ 2;
  final bySegment = <int, List<int>>{};
  for (var s = 0; s < count; s++) {
    (bySegment[pairs[2 * s]] ??= <int>[]).add(s);
    (bySegment[pairs[2 * s + 1]] ??= <int>[]).add(s);
  }
  final used = List<bool>.filled(count, false);
  final out = <List<int>>[];

  // Walks from [edge] away from segment [from], appending edges to [line].
  // Returns true when the walk came back to [stopAt] (a closed ring).
  bool walk(int edge, int from, int stopAt, List<int> line) {
    var current = edge;
    var last = from;
    while (true) {
      final next = bySegment[current]!.where((s) => s != last && !used[s]);
      if (next.isEmpty) return false;
      final s = next.first;
      used[s] = true;
      final other = pairs[2 * s] == current ? pairs[2 * s + 1] : pairs[2 * s];
      line.add(other);
      if (other == stopAt) return true;
      last = s;
      current = other;
    }
  }

  // Open lines first: start from edges touched by a single segment, so a
  // line that ends at the tile edge is walked from its end and never split.
  for (var s = 0; s < count; s++) {
    if (used[s]) continue;
    final a = pairs[2 * s], b = pairs[2 * s + 1];
    final aOpen = bySegment[a]!.length == 1;
    final bOpen = bySegment[b]!.length == 1;
    if (!aOpen && !bOpen) continue;
    used[s] = true;
    final start = aOpen ? a : b;
    final line = [start, aOpen ? b : a];
    walk(line.last, s, start, line);
    out.add(line);
  }
  // Whatever remains is closed rings.
  for (var s = 0; s < count; s++) {
    if (used[s]) continue;
    used[s] = true;
    final a = pairs[2 * s], b = pairs[2 * s + 1];
    final line = [a, b];
    if (!walk(b, s, a, line)) {
      // A broken ring (should not happen on a consistent grid): extend the
      // other way so no segment is lost.
      final back = <int>[];
      walk(a, s, b, back);
      line.insertAll(0, back.reversed);
    }
    out.add(line);
  }
  return out;
}

/// One pass of Chaikin corner cutting. Open lines keep their endpoints (they
/// sit exactly on the tile edge); rings are cut all the way round.
List<List<double>> _chaikin(List<List<double>> pts, bool closed) {
  if (pts.length < 3) return pts;
  final out = <List<double>>[];
  final last = closed ? pts.length - 1 : pts.length - 1;
  if (!closed) out.add(pts.first);
  for (var i = 0; i < last; i++) {
    final p = pts[i], q = pts[i + 1];
    out.add([0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]]);
    out.add([0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1]]);
  }
  if (closed) {
    out.add(out.first);
  } else {
    out.add(pts.last);
  }
  return out;
}

/// Ramer-Douglas-Peucker in the plane (pixel coordinates), keeping the ends.
List<List<double>> simplifyPixels(List<List<double>> pts, double tolerance) {
  if (pts.length < 3 || tolerance <= 0) return pts;
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = true;
  keep[pts.length - 1] = true;
  final stack = <(int, int)>[(0, pts.length - 1)];
  while (stack.isNotEmpty) {
    final (first, last) = stack.removeLast();
    if (last <= first + 1) continue;
    var maxD = 0.0;
    var index = first;
    final ax = pts[first][0], ay = pts[first][1];
    final bx = pts[last][0], by = pts[last][1];
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    for (var i = first + 1; i < last; i++) {
      final px = pts[i][0], py = pts[i][1];
      double d;
      if (len2 == 0) {
        d = math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
      } else {
        final t = (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
        final cx = ax + t * dx, cy = ay + t * dy;
        d = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
      }
      if (d > maxD) {
        maxD = d;
        index = i;
      }
    }
    if (maxD > tolerance) {
      keep[index] = true;
      stack.add((first, index));
      stack.add((index, last));
    }
  }
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i]
  ];
}

/// Builds the (256 + 1) square grid [contourTile] wants from a tile's own
/// samples and its east, south, and southeast neighbors' first column, row,
/// and corner. A missing neighbor repeats the tile's own edge, so lines still
/// reach the boundary (they just stop there).
Float32List stitchTileGrid(
  Float32List main, {
  Float32List? east,
  Float32List? south,
  Float32List? southEast,
}) {
  const s = 256;
  const n = s + 1;
  final g = Float32List(n * n);
  const lastRow = s * n;
  for (var j = 0; j < s; j++) {
    final src = j * s;
    final dst = j * n;
    for (var i = 0; i < s; i++) {
      g[dst + i] = main[src + i];
    }
    g[dst + s] = east == null ? main[src + s - 1] : east[j * s];
  }
  for (var i = 0; i < s; i++) {
    g[lastRow + i] = south == null ? main[(s - 1) * s + i] : south[i];
  }
  g[lastRow + s] = southEast != null
      ? southEast[0]
      : east != null
          ? east[(s - 1) * s]
          : south != null
              ? south[s - 1]
              : main[s * s - 1];
  return g;
}
