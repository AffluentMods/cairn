// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/data/repositories/elevation_repository_impl.dart';
import 'package:cairn/data/sources/terrain_tile_source.dart';
import 'package:cairn/domain/usecases/compute_route_stats.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A terrain source with nothing cached and no network.
class _NoTiles extends TerrainTileSource {
  _NoTiles() : super(Dio(), Directory.systemTemp);

  @override
  Future<List<double?>> elevations(List<List<double>> latLon) async =>
      List<double?>.filled(latLon.length, null);

  @override
  Future<double?> elevationAt(double lat, double lon) async => null;
}

void main() {
  final points = [
    for (var i = 0; i < 10; i++) [46.0 + i * 0.001, -121.0]
  ];

  test('falls back to the remote lookup and interpolates between anchors',
      () async {
    var asked = 0;
    final repo = ElevationRepositoryImpl(
      _NoTiles(),
      remote: (latLon) async {
        asked = latLon.length;
        // 100 m per 0.001 deg of latitude.
        return [for (final p in latLon) (p[0] - 46.0) * 100000];
      },
    );
    final elevs = await repo.elevationsAlong(points);
    expect(asked, 10);
    expect(elevs.length, 10);
    expect(elevs.first, closeTo(0, 1e-6));
    expect(elevs.last, closeTo(900, 1e-6));
  });

  test('spreads a long line over 100 anchors and interpolates the rest',
      () async {
    final long = [
      for (var i = 0; i < 1000; i++) [46.0 + i * 0.0001, -121.0]
    ];
    var asked = 0;
    final repo = ElevationRepositoryImpl(
      _NoTiles(),
      remote: (latLon) async {
        asked = latLon.length;
        return [for (final p in latLon) (p[0] - 46.0) * 100000];
      },
    );
    final elevs = await repo.elevationsAlong(long);
    expect(asked, 100);
    expect(elevs.length, 1000);
    // Linear ground (0.0001 deg is 10 m of rise): interpolation reproduces
    // it closely everywhere.
    expect(elevs[500], closeTo(5000, 2));
  });

  test('nothing known anywhere gives an empty list, and stats stay honest',
      () async {
    final repo = ElevationRepositoryImpl(
      _NoTiles(),
      remote: (_) async => null,
    );
    final elevs = await repo.elevationsAlong(points);
    expect(elevs, isEmpty);

    final stats = await computeRouteStats(points, repo);
    expect(stats.distanceM, greaterThan(900));
    expect(stats.profile, isEmpty);
    expect(stats.gainM, 0);
    expect(stats.estimatedTime, greaterThan(Duration.zero));
  });
}
