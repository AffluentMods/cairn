// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/sources/location_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulateAlong walks the route with a heading and marks fixes mocked',
      () async {
    final route = [
      [46.0, -121.0],
      [46.0, -120.99], // due east
      [46.01, -120.99], // due north
    ];
    // Large step per tick so the walk advances noticeably within the segment.
    final fixes = await simulateAlong(
      route,
      speedMps: 10000,
      interval: const Duration(milliseconds: 5),
    ).take(3).toList();

    expect(fixes, hasLength(3));
    expect(fixes.first.latitude, closeTo(46.0, 1e-6));
    expect(fixes.first.heading, closeTo(90, 5)); // heading east on segment 1
    expect(fixes[1].longitude, greaterThan(fixes.first.longitude)); // moved east
    expect(fixes.every((f) => f.isMocked), isTrue);
  });

  test('a degenerate route emits nothing', () async {
    expect(
      await simulateAlong([
        [46.0, -121.0],
      ]).take(1).toList(),
      isEmpty,
    );
  });
}
