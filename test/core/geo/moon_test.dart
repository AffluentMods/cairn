// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/moon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const synodic = 29.530588853;
  // Reference new moon used by the implementation.
  final epoch = DateTime.utc(2000, 1, 6, 18, 14);

  group('computeMoon anchors (exact by the mean-cycle construction)', () {
    test('at the epoch the moon is new, near 0 percent lit', () {
      final m = computeMoon(epoch);
      expect(m.illuminationPercent, lessThan(2));
      expect(m.phase, MoonPhase.newMoon);
    });

    test('half a synodic month later is full, near 100 percent', () {
      final m = computeMoon(
        epoch.add(Duration(milliseconds: (synodic / 2 * 86400000).round())),
      );
      expect(m.illuminationPercent, greaterThan(98));
      expect(m.phase, MoonPhase.full);
    });

    test('a quarter later is a half-lit quarter moon', () {
      final m = computeMoon(
        epoch.add(Duration(milliseconds: (synodic / 4 * 86400000).round())),
      );
      expect(m.illuminationPercent, closeTo(50, 3));
      expect(m.phase, MoonPhase.firstQuarter);
    });
  });

  test('2026-07-25 is a waxing gibbous, high but not full', () {
    // Regression pin: mean-cycle method gives ~82 percent, age ~10.7 d, a few
    // days before the late-July 2026 full moon. Cross-check against a live
    // reference before trusting to the last point (docs/API_NOTES.md).
    final m = computeMoon(DateTime.utc(2026, 7, 25, 12));
    expect(m.phase, MoonPhase.waxingGibbous);
    expect(m.illuminationPercent, closeTo(82, 5));
    expect(m.age, closeTo(10.7, 1.0));
  });
}
