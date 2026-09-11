// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/solar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeSolarTimes: Tacoma 2026-09-10', () {
    // Verified against api.sunrise-sunset.org (NOAA algorithm): sunrise
    // 13:39:44Z, sunset next-day 02:33:31Z, day length 46427 s. The spec's
    // "19:26 PDT" figure was rough and is superseded (see docs/API_NOTES.md).
    final s = computeSolarTimes(DateTime(2026, 9, 10), 47.2529, -122.4443);

    test('sunrise within 2 minutes of the reference', () {
      final diff = s.sunrise!
          .difference(DateTime.utc(2026, 9, 10, 13, 39, 44))
          .inSeconds
          .abs();
      expect(diff, lessThan(120));
    });

    test('sunset within 2 minutes of the reference', () {
      final diff = s.sunset!
          .difference(DateTime.utc(2026, 9, 11, 2, 33, 31))
          .inSeconds
          .abs();
      expect(diff, lessThan(120));
    });

    test('daylight is about 12 h 53 m', () {
      expect(s.daylight.inMinutes, closeTo(774, 3));
    });

    test('civil dawn precedes sunrise and civil dusk follows sunset', () {
      expect(s.civilDawn!.isBefore(s.sunrise!), isTrue);
      expect(s.civilDusk!.isAfter(s.sunset!), isTrue);
    });

    test('not a polar day or night at this latitude', () {
      expect(s.polarDay, isFalse);
      expect(s.polarNight, isFalse);
    });
  });

  test('polar night is detected above the Arctic Circle in December', () {
    final s = computeSolarTimes(DateTime(2026, 12, 21), 78.0, 15.0);
    expect(s.polarNight, isTrue);
    expect(s.sunrise, isNull);
    expect(s.daylight, Duration.zero);
  });
}
