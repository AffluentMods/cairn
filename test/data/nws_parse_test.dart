// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:cairn/data/sources/nws_source.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('hourly forecast: periods become SI hours, bad rows are skipped', () {
    final f = parseNwsHourly(
      _fixture('nws_hourly.json'),
      label: 'Trailhead',
      elevationM: 1385,
    );
    expect(f, isNotNull);
    expect(f!.label, 'Trailhead');
    expect(f.elevationM, 1385);
    // Three periods in the file; the third has an unparseable startTime.
    expect(f.hours.length, 2);
    final first = f.hours.first;
    expect(first.time, DateTime.parse('2026-09-11T20:00:00-07:00'));
    expect(first.tempC, closeTo((45 - 32) * 5 / 9, 1e-9));
    expect(first.precipProbability, 1);
    expect(first.windMps, closeTo(2 * 0.44704, 1e-9));
    expect(first.gustMps, isNull);
    expect(first.shortForecast, 'Mostly Cloudy');
    // "5 to 10 mph" keeps the higher number; gusts parse the same way.
    final second = f.hours[1];
    expect(second.windMps, closeTo(10 * 0.44704, 1e-9));
    expect(second.gustMps, closeTo(20 * 0.44704, 1e-9));
    expect(second.precipProbability, 0);
  });

  test('hourly forecast with no periods is null', () {
    expect(parseNwsHourly({}, label: 'x', elevationM: 0), isNull);
    expect(
      parseNwsHourly({
        'properties': {'periods': []}
      }, label: 'x', elevationM: 0),
      isNull,
    );
  });

  test('alerts: event, severity and end time; no event means no alert', () {
    final alerts = parseNwsAlerts(_fixture('nws_alerts.json'));
    expect(alerts.length, 2);
    expect(alerts.first.event, 'Red Flag Warning');
    expect(alerts.first.severity, 'Severe');
    expect(alerts.first.ends, DateTime.parse('2026-09-12T20:00:00-07:00'));
    expect(alerts[1].event, 'Heat Advisory');
    expect(alerts[1].ends, isNull);
  });

  test('alerts: an empty collection parses to nothing', () {
    expect(parseNwsAlerts({'features': []}), isEmpty);
    expect(parseNwsAlerts({}), isEmpty);
  });
}
