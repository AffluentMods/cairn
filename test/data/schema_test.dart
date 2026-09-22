// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema is at v8', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 8);
  });

  test('UsfsRoads round-trips a segment with its access map (v7)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.usfsRoads).insert(
          UsfsRoadsCompanion.insert(
            id: 'r2100011',
            routeId: '2100011',
            number: '2100-011',
            name: const Value('Metzler'),
            kind: 'road',
            symbol: 3,
            accessJson: const Value('{"passengerVehicle":"yearlong"}'),
            geomJson: '[[46.57,-121.69],[46.573,-121.694]]',
            minLat: 46.57,
            minLon: -121.694,
            maxLat: 46.573,
            maxLon: -121.69,
          ),
        );
    final row = await db.select(db.usfsRoads).getSingle();
    expect(row.number, '2100-011');
    expect(row.seasonal, isFalse);
    expect(row.accessJson, contains('passengerVehicle'));
  });

  test('v6 cleanup drops cached sidewalks and keeps trails', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    OsmWaysCompanion way(int id, String tagsJson) => OsmWaysCompanion.insert(
          id: Value(id),
          highway: 'footway',
          tagsJson: tagsJson,
          geomJson: '[[47.59,-120.66],[47.591,-120.661]]',
          firstNodeId: 1,
          lastNodeId: 2,
          lengthM: 120,
          minLat: 47.59,
          minLon: -120.661,
          maxLat: 47.591,
          maxLon: -120.66,
        );
    await db
        .into(db.osmWays)
        .insert(way(1, '{"highway":"footway","footway":"sidewalk"}'));
    await db
        .into(db.osmWays)
        .insert(way(2, '{"highway":"footway","footway":"crossing"}'));
    await db
        .into(db.osmWays)
        .insert(way(3, '{"highway":"footway","name":"River Trail"}'));
    await db.deleteCachedStreetFurniture();
    final left = await db.select(db.osmWays).get();
    expect(left.map((w) => w.id).toList(), [3]);
  });

  test('Tracks carry battery start and end (v5)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: 't1',
            name: 'Hike',
            startedAt: DateTime(2026, 9, 11, 8),
            batteryStartPct: const Value(90),
            batteryEndPct: const Value(72),
          ),
        );
    final row = await db.select(db.tracks).getSingle();
    expect(row.batteryStartPct, 90);
    expect(row.batteryEndPct, 72);
  });

  test('CustomThemes round-trips (Fix Pass 1 X4.4, v4)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.customThemes).insert(
          CustomThemesCompanion.insert(
            id: 'custom-1',
            name: 'My Theme',
            isDark: true,
            accent: 0xFFD9A441,
            background: 0xFF0E1412,
            surface: 0xFF15201B,
            raised: 0xFF1E2C25,
            outline: 0xFF2E3B34,
            textPrimary: 0xFFF1EEE6,
            textSecondary: 0xFFA9B0AB,
            route: 0xFFD9A441,
            track: 0xFF3FB8AF,
            createdAt: DateTime(2026, 9, 11),
          ),
        );
    final themes = await db.select(db.customThemes).get();
    expect(themes, hasLength(1));
    expect(themes.single.name, 'My Theme');
    expect(themes.single.accent, 0xFFD9A441);
  });

  test('FavoriteTrails and UserWaypoints round-trip (Phase R, A7)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.favoriteTrails).insert(
          FavoriteTrailsCompanion.insert(
            trailId: 'r123',
            name: 'Snowgrass Trail',
            centerLat: 46.44,
            centerLon: -121.47,
            lengthM: const Value(7400),
            savedAt: DateTime(2026, 9, 11),
          ),
        );
    final favs = await db.select(db.favoriteTrails).get();
    expect(favs, hasLength(1));
    expect(favs.single.trailId, 'r123');
    expect(favs.single.lengthM, 7400);

    await db.into(db.userWaypoints).insert(
          UserWaypointsCompanion.insert(
            id: 'wp1',
            kind: 'water',
            lat: 46.44,
            lon: -121.47,
            createdAt: DateTime(2026, 9, 11),
          ),
        );
    final wps = await db.select(db.userWaypoints).get();
    expect(wps.single.kind, 'water');
    expect(wps.single.routeId, null);
  });
}
