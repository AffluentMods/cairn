// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/haversine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineMeters', () {
    test('one degree of latitude is about 111.19 km', () {
      final d = haversineMeters(0, 0, 1, 0);
      expect(d, closeTo(111194.9, 111194.9 * 0.001));
    });

    test('one degree of longitude at the equator is about 111.19 km', () {
      final d = haversineMeters(0, 0, 0, 1);
      expect(d, closeTo(111194.9, 111194.9 * 0.001));
    });

    test('same point is zero', () {
      expect(haversineMeters(47.25, -122.44, 47.25, -122.44), closeTo(0, 1e-6));
    });

    test('Tacoma to Seattle is roughly 40 km', () {
      final d = haversineMeters(47.2529, -122.4443, 47.6062, -122.3321);
      expect(d, greaterThan(39000));
      expect(d, lessThan(41500));
    });
  });

  test('polylineLengthMeters sums segments', () {
    final len = polylineLengthMeters([
      [0, 0],
      [0, 1],
      [1, 1],
    ]);
    expect(len, closeTo(111194.9 * 2, 111194.9 * 2 * 0.001));
  });

  group('bearingDegrees', () {
    test('due north', () {
      expect(bearingDegrees(0, 0, 1, 0), closeTo(0, 0.01));
    });
    test('due east', () {
      expect(bearingDegrees(0, 0, 0, 1), closeTo(90, 0.01));
    });
  });
}
