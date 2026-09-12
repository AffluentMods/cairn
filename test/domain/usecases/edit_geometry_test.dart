// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/edit_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A straight north-south line with three waypoints on it.
  final line = [
    for (var i = 0; i <= 10; i++) [46.40 + i * 0.001, -121.40],
  ];
  final waypoints = [
    [46.400, -121.40],
    [46.405, -121.40],
    [46.410, -121.40],
  ];

  test('meters per pixel follows Web Mercator', () {
    expect(metersPerPixel(0, 0), closeTo(156543.03, 0.1));
    expect(metersPerPixel(0, 10), closeTo(152.87, 0.01));
    expect(metersPerPixel(60, 10), closeTo(76.44, 0.01));
  });

  test('a tap on the first leg inserts between waypoints 1 and 2', () {
    final idx =
        insertIndexForTap(line, waypoints, 46.4025, -121.40001, toleranceM: 30);
    expect(idx, 1);
  });

  test('a tap on the second leg inserts between waypoints 2 and 3', () {
    final idx =
        insertIndexForTap(line, waypoints, 46.408, -121.4001, toleranceM: 30);
    expect(idx, 2);
  });

  test('a tap away from the line appends instead', () {
    // 0.01 degrees of longitude at 46 N is roughly 770 m.
    final idx =
        insertIndexForTap(line, waypoints, 46.405, -121.41, toleranceM: 30);
    expect(idx, isNull);
  });

  test('fewer than two waypoints never inserts', () {
    expect(
      insertIndexForTap(line, [waypoints.first], 46.405, -121.40,
          toleranceM: 30),
      isNull,
    );
  });

  test('on a leg that doubles back, the first bracketing pair wins', () {
    // Waypoints out of line order: positions 0.0, 10.0, 5.0 along the line.
    final loopWaypoints = [
      [46.400, -121.40],
      [46.410, -121.40],
      [46.405, -121.40],
    ];
    // Position 8 lies inside both (0, 10) and (10, 5); the first leg takes it.
    final idx =
        insertIndexForTap(line, loopWaypoints, 46.408, -121.40, toleranceM: 30);
    expect(idx, 1);
    // Position 3 lies inside (0, 10) only.
    expect(
      insertIndexForTap(line, loopWaypoints, 46.403, -121.40, toleranceM: 30),
      1,
    );
  });

  test('a tap on the line outside every pair goes after the nearest', () {
    // Waypoints at positions 2 and 4; the tap at 8 is on the line but past
    // both, so it lands after the last waypoint (index clamped to 1).
    final wps = [
      [46.402, -121.40],
      [46.404, -121.40],
    ];
    expect(insertIndexForTap(line, wps, 46.408, -121.40, toleranceM: 30), 1);
  });
}
