// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/trip_calories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trip calories (Pandolf)', () {
    test('uphill burns more than flat at the same speed', () {
      final flat = tripCaloriesKcal(
        bodyKg: 75,
        packKg: 20,
        segments: const [
          CalorieSegment(distanceM: 1000, elevDeltaM: 0, seconds: 720),
        ],
      );
      final uphill = tripCaloriesKcal(
        bodyKg: 75,
        packKg: 20,
        segments: const [
          CalorieSegment(distanceM: 1000, elevDeltaM: 150, seconds: 720),
        ],
      );
      expect(uphill, greaterThan(flat));
      expect(flat, greaterThan(0));
    });

    test('a heavier pack burns more', () {
      const seg = [
        CalorieSegment(distanceM: 1000, elevDeltaM: 100, seconds: 720)
      ];
      final light = tripCaloriesKcal(bodyKg: 75, packKg: 5, segments: seg);
      final heavy = tripCaloriesKcal(bodyKg: 75, packKg: 25, segments: seg);
      expect(heavy, greaterThan(light));
    });

    test('zero body mass is zero', () {
      expect(
        tripCaloriesKcal(
          bodyKg: 0,
          packKg: 10,
          segments: const [
            CalorieSegment(distanceM: 1000, elevDeltaM: 0, seconds: 600),
          ],
        ),
        0,
      );
    });
  });
}
