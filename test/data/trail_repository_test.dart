// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/repositories/trail_repository_impl.dart';
import 'package:cairn/data/sources/overpass_source.dart';
import 'package:cairn/data/sources/usfs_source.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrailRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TrailRepositoryImpl(
      db: db,
      overpass: OverpassSource(Dio()),
      usfs: UsfsSource(Dio()),
    );
  });

  tearDown(() async => db.close());

  Future<void> insertWay({
    required int id,
    required String name,
    required List<List<double>> geom,
  }) async {
    var minLat = geom.first[0], maxLat = geom.first[0];
    var minLon = geom.first[1], maxLon = geom.first[1];
    for (final p in geom) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    await db.into(db.osmWays).insert(
          OsmWaysCompanion.insert(
            id: Value(id),
            highway: 'path',
            tagsJson: '{}',
            geomJson: jsonEncode(geom),
            firstNodeId: 1,
            lastNodeId: 2,
            lengthM: 1000,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            name: Value(name),
          ),
        );
  }

  test('trailsInBbox returns only intersecting ways', () async {
    await insertWay(
      id: 1,
      name: 'Snowgrass Trail',
      geom: [
        [46.47, -121.46],
        [46.48, -121.45],
      ],
    );
    await insertWay(
      id: 2,
      name: 'Far Away Trail',
      geom: [
        [40.0, -120.0],
        [40.01, -120.01],
      ],
    );

    final near = await repo.trailsInBbox([46.46, -121.47, 46.49, -121.44]);
    expect(near.map((t) => t.id), [1]);
    expect(near.first.name, 'Snowgrass Trail');
    expect(near.first.geometry.length, 2);
  });

  test('searchByName matches on a LIKE query', () async {
    await insertWay(
      id: 1,
      name: 'Pacific Crest Trail',
      geom: [
        [46.47, -121.46],
        [46.48, -121.45],
      ],
    );
    final hits = await repo.searchByName('Crest');
    expect(hits.length, 1);
    expect(hits.first.id, 1);
    expect(await repo.searchByName('nothing here'), isEmpty);
  });

  test('byId decodes geometry', () async {
    await insertWay(
      id: 7,
      name: 'x',
      geom: [
        [46.0, -121.0],
        [46.1, -121.1],
      ],
    );
    final t = await repo.byId(7);
    expect(t, isNotNull);
    expect(t!.geometry, [
      [46.0, -121.0],
      [46.1, -121.1],
    ]);
  });
}
