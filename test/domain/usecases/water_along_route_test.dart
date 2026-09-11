// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/compute_route_stats.dart';
import 'package:cairn/domain/usecases/water_along_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final route = [
    [46.0, -121.00],
    [46.0, -120.99],
  ]; // about 770 m eastward

  test('keeps near-route water, drops far water, orders by distance', () {
    final waters = waterAlongRoute(route, const [
      WaterCandidate(
          lat: 46.0003, lon: -121.00, kind: 'spring', name: 'Goat Creek'),
      WaterCandidate(
          lat: 46.0003, lon: -120.992, kind: 'stream', name: 'Snowgrass Creek'),
      WaterCandidate(lat: 46.01, lon: -121.00, kind: 'water', name: 'Far Lake'),
    ]);
    expect(waters.length, 2);
    expect(waters.first.name, 'Goat Creek');
    expect(waters.last.name, 'Snowgrass Creek');
    expect(waters.first.distanceAlongM, lessThan(waters.last.distanceAlongM));
  });

  test('flags the last water before the longest climb', () {
    const profile = [
      ProfilePoint(0, 1000),
      ProfilePoint(300, 1000),
      ProfilePoint(600, 990),
      ProfilePoint(770, 1090), // longest climb starts at 600
    ];
    final waters = waterAlongRoute(
      route,
      const [
        WaterCandidate(
            lat: 46.0003, lon: -121.00, kind: 'spring', name: 'early'),
        WaterCandidate(
            lat: 46.0003, lon: -120.992, kind: 'stream', name: 'late'),
      ],
      profile: profile,
    );
    final early = waters.firstWhere((w) => w.name == 'early');
    final late = waters.firstWhere((w) => w.name == 'late');
    expect(early.lastBeforeClimb, isTrue);
    expect(late.lastBeforeClimb, isFalse);
  });

  test('empty route yields no water', () {
    expect(waterAlongRoute(const [], const []), isEmpty);
  });
}
