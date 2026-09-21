// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:cairn/core/worker/geo_worker.dart';
import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/repositories/poi_repository_impl.dart';
import 'package:cairn/data/repositories/trail_repository_impl.dart';
import 'package:cairn/data/sources/overpass_source.dart';
import 'package:cairn/data/sources/usfs_source.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';

/// Serves the recorded Snowgrass response for ways and one spring for POIs,
/// so ingestion runs end to end without a network.
class _FakeOverpass extends OverpassSource {
  _FakeOverpass() : super(Dio());

  @override
  Future<String> fetchWays(List<double> bbox) async =>
      File('test/fixtures/overpass_snowgrass.json').readAsStringSync();

  @override
  Future<String> fetchPois(List<double> bbox) async => jsonEncode({
        'elements': [
          {
            'type': 'node',
            'id': 1,
            'lat': 46.47,
            'lon': -121.46,
            'tags': {'natural': 'spring', 'name': 'Goat Spring'},
          },
        ],
      });
}

/// Every mirror is down.
class _DownOverpass extends OverpassSource {
  _DownOverpass() : super(Dio());

  @override
  Future<String> fetchWays(List<double> bbox) async =>
      throw OverpassUnavailable('down');
}

class _NoUsfs extends UsfsSource {
  _NoUsfs() : super(Dio());

  @override
  Future<Map<String, dynamic>?> fetchTrails(List<double> bbox) async => null;
}

void main() {
  late AppDatabase db;
  const bbox = [46.46, -121.47, 46.49, -121.44];

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    GeoWorker.unsendableFallbacks = 0;
  });

  tearDown(() async => db.close());

  // Regression guard: the parse used to run through a closure built inside
  // the repository method, which captured the repository (and its database)
  // and was refused by Isolate.run as unsendable, so no new map cell ever
  // ingested. The worker path must succeed without the inline fallback.
  test('trail cells ingest through the worker isolate', () async {
    final repo = TrailRepositoryImpl(
      db: db,
      overpass: _FakeOverpass(),
      usfs: _NoUsfs(),
    );
    final result = await repo.ensureArea(bbox);
    expect(result.networkError, isFalse);
    expect(result.cellsFetched, greaterThan(0));
    expect(GeoWorker.unsendableFallbacks, 0);

    final ways = await db.select(db.osmWays).get();
    expect(ways, isNotEmpty);
    // The recorded response covers the PCT and Bypass Trail at Goat Rocks.
    final trails = await repo.trailsInBbox(bbox);
    expect(trails.any((t) => (t.name ?? '').contains('Bypass Trail')), isTrue);
    expect(
      trails.any((t) => (t.name ?? '').contains('Pacific Crest Trail')),
      isTrue,
    );

    // A second pass finds the cells fresh and fetches nothing.
    final again = await repo.ensureArea(bbox);
    expect(again.cellsFetched, 0);
  });

  test('a cancelled refresh stops before fetching the next cell', () async {
    final repo = TrailRepositoryImpl(
      db: db,
      overpass: _FakeOverpass(),
      usfs: _NoUsfs(),
    );
    // Two cells wide; cancel after the first fetch.
    var fetched = 0;
    final result = await repo.ensureArea(
      [46.46, -121.47, 46.49, -121.0],
      isCancelled: () => fetched++ > 0,
    );
    expect(result.cellsFetched, 1);
    expect(result.networkError, isFalse);
  });

  test('progress reports a real total before the first query, then each cell',
      () async {
    final repo = TrailRepositoryImpl(
      db: db,
      overpass: _FakeOverpass(),
      usfs: _NoUsfs(),
    );
    // Two z10 cells wide.
    const wide = [46.46, -121.47, 46.49, -121.0];
    final calls = <(int, int, bool)>[];
    await repo.ensureArea(
      wide,
      onCell: (done, total, fetched) async => calls.add((done, total, fetched)),
    );
    expect(calls, [(0, 2, false), (1, 2, true), (2, 2, true)]);

    // Everything is fresh now: no progress at all, so no loading pill.
    calls.clear();
    await repo.ensureArea(
      wide,
      onCell: (done, total, fetched) async => calls.add((done, total, fetched)),
    );
    expect(calls, isEmpty);
  });

  test('a failing mirror reports the cell as done but not fetched', () async {
    final repo = TrailRepositoryImpl(
      db: db,
      overpass: _DownOverpass(),
      usfs: _NoUsfs(),
    );
    final calls = <(int, int, bool)>[];
    final result = await repo.ensureArea(
      bbox,
      onCell: (done, total, fetched) async => calls.add((done, total, fetched)),
    );
    expect(result.networkError, isTrue);
    expect(calls, [(0, 1, false), (1, 1, false)]);
  });

  test('POI cells ingest through the worker isolate', () async {
    final repo = PoiRepositoryImpl(db: db, overpass: _FakeOverpass());
    await repo.ensureArea(bbox);
    expect(GeoWorker.unsendableFallbacks, 0);
    final pois = await repo.poisInBbox(bbox);
    expect(pois.length, 1);
    expect(pois.first.kind, 'spring');
    expect(pois.first.name, 'Goat Spring');
  });
}
