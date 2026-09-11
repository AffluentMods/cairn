// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/route_between_waypoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routePenalty', () {
    test('base is 1.0, informal 1.4, difficult alpine 3.0', () {
      expect(routePenalty(informal: false), 1.0);
      expect(routePenalty(informal: true), closeTo(1.4, 1e-9));
      expect(
        routePenalty(informal: false, sacScale: 'difficult_alpine_hiking'),
        closeTo(3.0, 1e-9),
      );
    });
    test('private access is impassable', () {
      expect(routePenalty(informal: false, access: 'private'), double.infinity);
    });
  });

  group('routeBetweenWaypoints', () {
    // A single straight west-to-east way with three nodes.
    const way = RoutableWay(
      id: 1,
      nodeIds: [10, 11, 12],
      coords: [
        [46.0, -121.00],
        [46.0, -120.99],
        [46.0, -120.98],
      ],
      penalty: 1.0,
    );

    test('routes along the way between two snapped points', () {
      const a =
          SnappedPoint(wayId: 1, segmentIndex: 0, lat: 46.0, lon: -120.995);
      const b =
          SnappedPoint(wayId: 1, segmentIndex: 1, lat: 46.0, lon: -120.985);
      final r = routeBetweenWaypoints([way], a, b);
      expect(r.offTrail, isFalse);
      expect(r.polyline.first, [46.0, -120.995]);
      expect(r.polyline.last, [46.0, -120.985]);
      // Passes through the shared node 11 at -120.99.
      expect(r.polyline.any((p) => (p[1] - -120.99).abs() < 1e-9), isTrue);
      expect(r.lengthM, greaterThan(0));
    });

    test('same-segment leg is a direct sub-segment', () {
      const a =
          SnappedPoint(wayId: 1, segmentIndex: 0, lat: 46.0, lon: -120.998);
      const b =
          SnappedPoint(wayId: 1, segmentIndex: 0, lat: 46.0, lon: -120.992);
      final r = routeBetweenWaypoints([way], a, b);
      expect(r.offTrail, isFalse);
      expect(r.polyline.length, 2);
    });

    test('two ways joined at a shared node route through it', () {
      const wayA = RoutableWay(
        id: 1,
        nodeIds: [1, 2],
        coords: [
          [46.0, -121.0],
          [46.0, -120.99],
        ],
        penalty: 1.0,
      );
      const wayB = RoutableWay(
        id: 2,
        nodeIds: [2, 3], // shares node 2
        coords: [
          [46.0, -120.99],
          [46.01, -120.99],
        ],
        penalty: 1.0,
      );
      const a =
          SnappedPoint(wayId: 1, segmentIndex: 0, lat: 46.0, lon: -120.995);
      const b =
          SnappedPoint(wayId: 2, segmentIndex: 0, lat: 46.005, lon: -120.99);
      final r = routeBetweenWaypoints([wayA, wayB], a, b);
      expect(r.offTrail, isFalse);
      expect(r.polyline.any((p) => (p[1] - -120.99).abs() < 1e-9), isTrue);
    });

    test('disconnected waypoints fall back to an off-trail straight line', () {
      const farWay = RoutableWay(
        id: 2,
        nodeIds: [90, 91],
        coords: [
          [40.0, -100.0],
          [40.0, -99.99],
        ],
        penalty: 1.0,
      );
      const a =
          SnappedPoint(wayId: 1, segmentIndex: 0, lat: 46.0, lon: -120.995);
      const b =
          SnappedPoint(wayId: 2, segmentIndex: 0, lat: 40.0, lon: -99.995);
      final r = routeBetweenWaypoints([way, farWay], a, b);
      expect(r.offTrail, isTrue);
      expect(r.polyline.length, 2);
    });
  });
}
