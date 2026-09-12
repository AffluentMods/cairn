// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/chain_ways.dart';
import 'package:cairn/domain/usecases/trail_rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('difficulty', () {
    // The benchmark's AllTrails samples: score in the band AllTrails labels.
    test('matches the AllTrails labels sampled in the benchmark', () {
      double score(double mi, double ft) =>
          difficultyScore(distanceM: mi * 1609.344, gainM: ft * 0.3048);
      expect(difficultyLevel(score(5.9, 2824)), TrailDifficulty.hard);
      expect(difficultyLevel(score(7.3, 1263)), TrailDifficulty.moderate);
      expect(difficultyLevel(score(2.9, 869)), TrailDifficulty.moderate);
      expect(difficultyLevel(score(1.2, 85)), TrailDifficulty.easy);
      expect(difficultyLevel(score(12.5, 4900)), TrailDifficulty.strenuous);
      // Fay Canyon: easy by numbers, a scramble on an unmarked route.
      expect(
        difficultyLevel(score(2.1, 150), trailVisibility: 'bad'),
        TrailDifficulty.moderate,
      );
      expect(
        difficultyLevel(score(2.1, 150), sacScale: 'alpine_hiking'),
        TrailDifficulty.moderate,
      );
      // T2 is an ordinary mountain trail: no bump.
      expect(
        difficultyLevel(score(1.2, 85), sacScale: 'mountain_hiking'),
        TrailDifficulty.easy,
      );
    });

    test('typical time reproduces the published bands', () {
      // Dog Mountain 5.9 mi / 2,824 ft: AllTrails says 5 to 5.5 h.
      final s =
          typicalTimeSeconds(distanceM: 5.9 * 1609.344, gainM: 2824 * 0.3048);
      expect(hoursBand(s), (from: 5.0, to: 5.5));
      // A stroll never shows under half an hour.
      expect(hoursBand(600), (from: 0.5, to: 1.0));
    });
  });

  group('route type', () {
    test('a straight trail is point to point', () {
      final line = [
        for (var i = 0; i < 40; i++) [46.0 + i * 0.001, -121.0]
      ];
      expect(routeTypeOf(line), RouteType.pointToPoint);
    });

    test('a retraced trail is out and back', () {
      final out = [
        for (var i = 0; i < 40; i++) [46.0 + i * 0.001, -121.0]
      ];
      final line = [...out, ...out.reversed.skip(1)];
      expect(routeTypeOf(line), RouteType.outAndBack);
    });

    test('a square is a loop', () {
      final line = <List<double>>[];
      for (var i = 0; i <= 20; i++) {
        line.add([46.0, -121.0 + i * 0.001]);
      }
      for (var i = 1; i <= 20; i++) {
        line.add([46.0 + i * 0.001, -120.98]);
      }
      for (var i = 1; i <= 20; i++) {
        line.add([46.02, -120.98 - i * 0.001]);
      }
      for (var i = 1; i <= 20; i++) {
        line.add([46.02 - i * 0.001, -121.0]);
      }
      expect(routeTypeOf(line), RouteType.loop);
    });
  });

  group('chainWays', () {
    test('joins ways end to end in either orientation, longest chain first',
        () {
      final a = [
        for (var i = 0; i <= 10; i++) [46.0 + i * 0.001, -121.0]
      ];
      // b continues from a's end but is stored reversed.
      final b = [
        for (var i = 20; i >= 10; i--) [46.0 + i * 0.001, -121.0]
      ];
      // c precedes a.
      final c = [
        for (var i = -5; i <= 0; i++) [46.0 + i * 0.001, -121.0]
      ];
      // d is a same-named trail 5 km away: its own chain.
      final d = [
        for (var i = 0; i <= 3; i++) [46.05 + i * 0.001, -121.0]
      ];
      final chains = chainWays([a, b, c, d]);
      expect(chains.length, 2);
      final main = chains.first;
      // Either direction is fine for a trail; the ends must be the extremes.
      final ends = {main.first[0], main.last[0]};
      expect(ends, {closeTo(45.995, 1e-9), closeTo(46.02, 1e-9)});
      // Monotonic with no duplicated join vertices.
      final north = main.last[0] > main.first[0];
      for (var i = 1; i < main.length; i++) {
        expect(
            north ? main[i][0] > main[i - 1][0] : main[i][0] < main[i - 1][0],
            isTrue);
      }
      // c has 6 vertices, a and b 11 each; two shared join vertices.
      expect(main.length, 6 + 11 + 11 - 2);
      expect(chains.last.length, 4);
    });

    test('degenerate ways are dropped', () {
      expect(chainWays([[]]), isEmpty);
      expect(
          chainWays([
            [
              [46.0, -121.0]
            ]
          ]),
          isEmpty);
    });
  });
}
