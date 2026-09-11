// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/nearest_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects onto the middle of a segment', () {
    final line = [
      [0.0, 0.0],
      [0.0, 1.0],
    ];
    final n = nearestPointOnPolyline(0.001, 0.5, line)!;
    expect(n.lon, closeTo(0.5, 1e-6));
    expect(n.lat, closeTo(0.0, 1e-6));
    expect(n.segmentIndex, 0);
    expect(n.t, closeTo(0.5, 1e-3));
    // 0.001 degrees of latitude is about 111 m.
    expect(n.distanceM, closeTo(111.2, 3));
  });

  test('clamps to an endpoint when the query is past the end', () {
    final line = [
      [0.0, 0.0],
      [0.0, 1.0],
    ];
    final n = nearestPointOnPolyline(0.0, 2.0, line)!;
    expect(n.lon, closeTo(1.0, 1e-6));
    expect(n.t, closeTo(1.0, 1e-6));
  });

  test('picks the nearest of several segments', () {
    final line = [
      [0.0, 0.0],
      [0.0, 1.0],
      [1.0, 1.0],
    ];
    final n = nearestPointOnPolyline(0.9, 1.001, line)!;
    expect(n.segmentIndex, 1);
  });

  test('null for a degenerate line', () {
    expect(
      nearestPointOnPolyline(0, 0, [
        [0.0, 0.0],
      ]),
      isNull,
    );
  });
}
