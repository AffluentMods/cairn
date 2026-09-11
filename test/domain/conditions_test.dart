// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/polygon.dart';
import 'package:cairn/domain/models/air_quality.dart';
import 'package:cairn/domain/models/fire_incident.dart';
import 'package:cairn/domain/usecases/fire_proximity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aqiCategory at EPA breakpoints', () {
    final cases = {
      0: AqiCategory.good,
      50: AqiCategory.good,
      51: AqiCategory.moderate,
      100: AqiCategory.moderate,
      101: AqiCategory.usg,
      150: AqiCategory.usg,
      151: AqiCategory.unhealthy,
      200: AqiCategory.unhealthy,
      201: AqiCategory.veryUnhealthy,
      300: AqiCategory.veryUnhealthy,
      301: AqiCategory.hazardous,
      500: AqiCategory.hazardous,
    };
    cases.forEach((aqi, expected) {
      test('$aqi is $expected', () => expect(aqiCategory(aqi), expected));
    });
  });

  group('pointInRing', () {
    const ring = [
      [45.99, -121.01],
      [45.99, -120.99],
      [46.01, -120.99],
      [46.01, -121.01],
      [45.99, -121.01],
    ];
    test('inside', () => expect(pointInRing(46.0, -121.0, ring), isTrue));
    test('outside', () => expect(pointInRing(46.5, -121.0, ring), isFalse));
  });

  group('routeToFire', () {
    const perimeter = FireIncident(
      id: '1',
      name: 'Skyo Fire',
      polygons: [
        [
          [45.99, -121.01],
          [45.99, -120.99],
          [46.01, -120.99],
          [46.01, -121.01],
          [45.99, -121.01],
        ],
      ],
    );

    test('a route through the perimeter crosses', () {
      final rel = routeToFire([
        [45.98, -121.0],
        [46.0, -121.0],
        [46.02, -121.0],
      ], perimeter);
      expect(rel.crosses, isTrue);
      expect(rel.distanceM, 0);
    });

    test('a route outside gets a positive distance', () {
      final rel = routeToFire([
        [46.05, -121.0],
      ], perimeter);
      expect(rel.crosses, isFalse);
      expect(rel.distanceM, greaterThan(1000));
    });

    test('a point-only fire uses distance to the point', () {
      const point = FireIncident(id: '2', name: 'Spot', lat: 46.0, lon: -121.0);
      final rel = routeToFire([
        [46.01, -121.0],
      ], point);
      expect(rel.crosses, isFalse);
      expect(rel.distanceM, closeTo(1112, 60));
    });

    test('annotateFires sorts crossing fires first', () {
      const near =
          FireIncident(id: 'near', name: 'n', lat: 46.001, lon: -121.0);
      final result = annotateFires([
        [46.0, -121.0],
      ], [
        near,
        perimeter
      ]);
      expect(result.first.crossesRoute, isTrue);
    });
  });
}
