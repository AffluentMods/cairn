// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/repositories/elevation_repository.dart';
import 'package:cairn/domain/usecases/compute_route_stats.dart';
import 'package:cairn/domain/usecases/route_between_waypoints.dart';
import 'package:cairn/domain/usecases/snap_to_trail.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a triangular elevation profile: rises then falls, regardless of the
/// actual coordinates, so gain and loss are both positive and known-ish.
class _TriangleElevation implements ElevationRepository {
  @override
  Future<List<double>> elevationsAlong(List<List<double>> points) async {
    final n = points.length;
    return [
      for (var i = 0; i < n; i++) (i <= n ~/ 2 ? i : (n - 1 - i)) * 10.0,
    ];
  }

  @override
  Future<double?> elevationAt(double lat, double lon) async => 1000;
}

void main() {
  test('computeRouteStats: a hill has positive gain and loss and a profile',
      () async {
    // A straight eastward line, about 770 m long at this latitude.
    final line = [
      [46.0, -121.00],
      [46.0, -120.995],
      [46.0, -120.99],
    ];
    final stats = await computeRouteStats(line, _TriangleElevation());
    expect(stats.distanceM, greaterThan(500));
    expect(stats.gainM, greaterThan(0));
    expect(stats.lossM, greaterThan(0));
    expect(stats.profile.length, greaterThan(2));
    expect(stats.estimatedTime.inSeconds, greaterThan(0));
    // The profile's last distance equals the total distance.
    expect(stats.profile.last.distanceM, closeTo(stats.distanceM, 1));
  });

  test('computeRouteStats: empty for a degenerate line', () async {
    final stats = await computeRouteStats([
      [46.0, -121.0],
    ], _TriangleElevation());
    expect(stats, same(RouteStats.empty));
  });

  group('snapToTrail', () {
    const way = RoutableWay(
      id: 5,
      nodeIds: [1, 2],
      coords: [
        [46.0, -121.00],
        [46.0, -120.99],
      ],
      penalty: 1.0,
    );

    test('snaps a nearby tap onto the way', () {
      final r = snapToTrail(46.0003, -120.995, [way]);
      expect(r.onTrail, isTrue);
      expect(r.point.wayId, 5);
      expect(r.snapDistanceM, lessThan(40));
    });

    test('a far tap is off-trail', () {
      final r = snapToTrail(46.002, -120.995, [way]);
      expect(r.onTrail, isFalse);
      expect(r.point.wayId, offTrailWayId);
    });
  });

  group('buildRoute', () {
    const way = RoutableWay(
      id: 5,
      nodeIds: [1, 2, 3],
      coords: [
        [46.0, -121.00],
        [46.0, -120.99],
        [46.0, -120.98],
      ],
      penalty: 1.0,
    );

    test('snaps every waypoint and joins the legs on one trail', () {
      final built = buildRoute([
        way
      ], [
        [46.0003, -120.998],
        [46.0003, -120.982],
      ]);
      expect(built.onTrail, [true, true]);
      expect(built.offTrail, isFalse);
      expect(built.polyline.length, greaterThanOrEqualTo(2));
      // Runs west to east through the shared node at -120.99.
      expect(
        built.polyline.any((p) => (p[1] - -120.99).abs() < 1e-9),
        isTrue,
      );
    });

    test('a far waypoint is off-trail and flags the leg', () {
      final built = buildRoute([
        way
      ], [
        [46.0003, -120.998],
        [46.02, -120.98], // well beyond the snap radius
      ]);
      expect(built.onTrail.first, isTrue);
      expect(built.onTrail.last, isFalse);
      expect(built.offTrail, isTrue);
    });

    test('fewer than two waypoints is empty', () {
      expect(
          buildRoute([
            way
          ], [
            [46.0, -121.0],
          ]),
          same(BuiltRoute.empty));
    });
  });
}
