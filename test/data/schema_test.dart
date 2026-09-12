// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema is at v5', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 5);
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
