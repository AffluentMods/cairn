// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/recording_accumulator.dart';
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

  group('RecordingAccumulator', () {
    test('accumulates distance, moving time, and gain; filters junk', () {
      final acc = RecordingAccumulator();
      final t0 = DateTime.utc(2026, 9, 10, 8);
      // Walk north, climbing, one point every 10 s at ~1.1 m/s.
      var accepted = 0;
      for (var i = 0; i < 6; i++) {
        final ok = acc.add(
          RecordingSample(
            t: t0.add(Duration(seconds: i * 10)),
            lat: 46.0 + i * 0.0001, // ~11 m per step
            lon: -121.0,
            accuracyM: 8,
            elevM: 1000 + i * 6.0, // climbing 6 m per step
          ),
        );
        if (ok) accepted++;
      }
      expect(accepted, 6);
      final stats = acc.statsAt(t0.add(const Duration(seconds: 50)));
      expect(stats.distanceM, greaterThan(40));
      expect(stats.gainM, greaterThan(20));
      expect(stats.movingSeconds, greaterThan(0));
      expect(stats.pointCount, 6);
    });

    test('rejects a low-accuracy fix', () {
      final acc = RecordingAccumulator();
      final ok = acc.add(
        RecordingSample(
          t: DateTime.utc(2026),
          lat: 46,
          lon: -121,
          accuracyM: 80,
        ),
      );
      expect(ok, isFalse);
    });

    test('rejects a GPS jump', () {
      final acc = RecordingAccumulator();
      final t0 = DateTime.utc(2026);
      acc.add(RecordingSample(t: t0, lat: 46.0, lon: -121.0, accuracyM: 5));
      // 1 km in 1 second is 1000 m/s, far over the 12 m/s cap.
      final ok = acc.add(
        RecordingSample(
          t: t0.add(const Duration(seconds: 1)),
          lat: 46.01,
          lon: -121.0,
          accuracyM: 5,
        ),
      );
      expect(ok, isFalse);
    });
  });
}
