// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/elevation_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gainLoss', () {
    test('sawtooth over the threshold counts every leg', () {
      final s = gainLoss([0, 10, 0, 10, 0], threshold: 5);
      expect(s.gain, closeTo(20, 1e-9));
      expect(s.loss, closeTo(20, 1e-9));
      expect(s.maxElev, 10);
      expect(s.minElev, 0);
    });

    test('sub-threshold noise counts nothing', () {
      final s = gainLoss([0, 2, 0, 2, 0], threshold: 5);
      expect(s.gain, 0);
      expect(s.loss, 0);
    });

    test('a steady climb in small steps still totals the full gain', () {
      final s = gainLoss([0, 3, 6, 9, 12], threshold: 5);
      expect(s.gain, closeTo(12, 1e-9));
      expect(s.loss, 0);
    });

    test('empty and single-sample are safe', () {
      expect(gainLoss([]).gain, 0);
      expect(gainLoss([100]).maxElev, 100);
    });
  });

  group('naismithLangmuirSeconds', () {
    test('5 km flat plus 600 m of ascent is about 2 hours', () {
      final s = naismithLangmuirSeconds(
        distanceM: 5000,
        gainM: 600,
        gentleDescentM: 0,
        steepDescentM: 0,
      );
      expect(s, closeTo(7200, 1));
    });

    test('gentle descent shaves time, steep descent adds it', () {
      final gentle = naismithLangmuirSeconds(
        distanceM: 0,
        gainM: 0,
        gentleDescentM: 300,
        steepDescentM: 0,
      );
      expect(gentle, 0); // -600 s clamped to 0
      final steep = naismithLangmuirSeconds(
        distanceM: 0,
        gainM: 0,
        gentleDescentM: 0,
        steepDescentM: 300,
      );
      expect(steep, closeTo(600, 1));
    });
  });
}
