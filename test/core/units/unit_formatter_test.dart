// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/units/unit_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const imp = UnitFormatter(UnitSystem.imperial);
  const met = UnitFormatter(UnitSystem.metric);

  test('distance', () {
    expect(imp.distance(1609.344), '1.0 mi');
    expect(imp.distance(20000), '12.4 mi');
    expect(met.distance(1000), '1.0 km');
  });

  test('elevation grouped and signed', () {
    expect(imp.elevation(825), '2,707 ft');
    expect(met.elevation(825), '825 m');
    expect(imp.elevationSigned(825), '+2,707 ft');
    expect(imp.elevationSigned(-579.12), '-1,900 ft');
  });

  test('temperature', () {
    expect(imp.temperature(20), '68°F');
    expect(met.temperature(20), '20°C');
    expect(imp.temperature(0), '32°F');
  });

  test('speed and pace', () {
    // 1 mile in 10 minutes = 2.68224 m/s
    expect(imp.pace(2.68224), '10:00 /mi');
    expect(imp.speed(2.68224), '6.0 mph');
    expect(imp.pace(0), '--');
  });

  test('weight', () {
    expect(imp.weight(20), '44 lb');
    expect(met.weight(20), '20 kg');
  });

  test('durations', () {
    expect(
      UnitFormatter.durationHm(const Duration(hours: 2, minutes: 10)),
      '2h 10m',
    );
    expect(UnitFormatter.durationHm(const Duration(minutes: 45)), '45m');
    expect(
      UnitFormatter.durationClock(
        const Duration(hours: 2, minutes: 58, seconds: 53),
      ),
      '2:58:53',
    );
  });
}
