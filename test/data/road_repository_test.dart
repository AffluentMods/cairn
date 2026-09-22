// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/core/worker/geo_worker.dart';
import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/repositories/road_repository_impl.dart';
import 'package:cairn/data/sources/usfs_source.dart';
import 'package:cairn/presentation/map_common/roads_layer_sync.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';

/// Serves the fixture for the roads layer, one page, and nothing for the
/// motorized trails layer. Counts requests so paging can be asserted.
class _FakeUsfs extends UsfsSource {
  _FakeUsfs({this.pages = 1}) : super(Dio());

  final int pages;
  final requests = <(bool, int)>[];

  @override
  Future<String?> fetchMvumPage(
    List<double> bbox, {
    required bool trails,
    int offset = 0,
  }) async {
    requests.add((trails, offset));
    if (trails) return '{"type":"FeatureCollection","features":[]}';
    final body = File('test/fixtures/mvum_roads.json').readAsStringSync();
    final page = offset ~/ 1000;
    if (page < pages - 1) {
      // Flag more pages; the last page carries no flag.
      return body.replaceFirst(
          '"features"', '"exceededTransferLimit": true, "features"');
    }
    return body;
  }
}

class _DownUsfs extends UsfsSource {
  _DownUsfs() : super(Dio());

  @override
  Future<String?> fetchMvumPage(
    List<double> bbox, {
    required bool trails,
    int offset = 0,
  }) async =>
      null;
}

void main() {
  late AppDatabase db;
  // A box inside one z10 cell (166, 362) south of Packwood, so ensureArea
  // fetches one cell; reads use a wide box around every fixture road.
  const bbox = [46.50, -121.60, 46.51, -121.59];
  const wide = [46.4, -121.8, 46.7, -121.4];

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    GeoWorker.unsendableFallbacks = 0;
  });

  tearDown(() async => db.close());

  test('a cell ingests through the worker and reads back by bbox and id',
      () async {
    final usfs = _FakeUsfs();
    final repo = RoadRepositoryImpl(db: db, usfs: usfs);
    await repo.ensureArea(bbox);
    expect(GeoWorker.unsendableFallbacks, 0);
    // Roads page then trails page for the one cell.
    expect(usfs.requests, [(false, 0), (true, 0)]);

    final roads = await repo.roadsInBbox(wide);
    expect(roads.map((r) => r.number).toSet(),
        containsAll(['2100-011', '4840', '2100-084', '2100']));
    // Roads sort longest first.
    expect(roads.first.number, '4840');

    final spur = await repo.byId('r2100011');
    expect(spur, isNotNull);
    expect(spur!.name, 'Metzler');
    expect(spur.access.map((a) => a.vehicle),
        ['passengerVehicle', 'highClearance']);
    expect(spur.surfaceCode, 'NAT');

    // Fresh now: no second fetch.
    await repo.ensureArea(bbox);
    expect(usfs.requests.length, 2);
  });

  test('a cut-short page is followed by the next offset', () async {
    final usfs = _FakeUsfs(pages: 3);
    final repo = RoadRepositoryImpl(db: db, usfs: usfs);
    await repo.ensureArea(bbox);
    expect(
      usfs.requests,
      [(false, 0), (false, 1000), (false, 2000), (true, 0)],
    );
  });

  test('an unreachable service leaves the cell unmarked', () async {
    final repo = RoadRepositoryImpl(db: db, usfs: _DownUsfs());
    await repo.ensureArea(bbox);
    expect(await repo.roadsInBbox(wide), isEmpty);
    final cells = await db.select(db.cacheCells).get();
    expect(cells, isEmpty);
  });

  test('roads become labeled, classed GeoJSON lines', () async {
    final repo = RoadRepositoryImpl(db: db, usfs: _FakeUsfs());
    await repo.ensureArea(bbox);
    final roads = await repo.roadsInBbox(wide);
    final geojson = roadsToGeoJson(roads, zoom: 14);
    final features = (geojson['features'] as List).cast<Map<String, dynamic>>();
    expect(features.length, roads.length);
    final props = features.map((f) => f['properties'] as Map).toList();
    expect(props.map((p) => p['kind']).toSet(), {'road'});
    expect(props.where((p) => p['seasonal'] == 1).length, 2);
    expect(props.map((p) => p['number']), contains('2100-011'));
    final coords =
        (features.first['geometry'] as Map)['coordinates'] as List<dynamic>;
    // GeoJSON is [lon, lat].
    expect((coords.first as List)[0], lessThan(-100));
    expect(roadsSignature(roads, 14), isNot(roadsSignature(roads, 11)));
  });
}
