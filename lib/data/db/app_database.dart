// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// OSM ids are stored as plain integers, not BigInt. Cairn is mobile only (no
// web, spec Q&A), where Dart int and SQLite INTEGER are both 64-bit, and current
// OSM way/node ids are far below 2^53. This avoids BigInt friction everywhere.

/// OSM ways: one row per way. Geometry is a compact JSON array of [lat, lon]
/// pairs so rendering needs no join. Bbox columns are indexed for viewport
/// queries (spec Section 7).
@TableIndex(
    name: 'idx_ways_bbox', columns: {#minLat, #maxLat, #minLon, #maxLon})
class OsmWays extends Table {
  IntColumn get id => integer()(); // OSM way id
  TextColumn get name => text().nullable()();
  TextColumn get highway => text()(); // path, footway, track...
  TextColumn get sacScale => text().nullable()();
  TextColumn get trailVisibility => text().nullable()();
  TextColumn get surface => text().nullable()();
  BoolColumn get informal => boolean().withDefault(const Constant(false))();
  TextColumn get tagsJson => text()();
  TextColumn get geomJson => text()(); // [[lat,lon],...]
  // OSM node ids aligned to geomJson, so the routing graph can connect ways at
  // shared nodes (spec Section 8, Phase 3).
  TextColumn get nodeIdsJson => text().withDefault(const Constant('[]'))();
  IntColumn get firstNodeId => integer()();
  IntColumn get lastNodeId => integer()();
  RealColumn get lengthM => real()();
  RealColumn get minLat => real()();
  RealColumn get minLon => real()();
  RealColumn get maxLat => real()();
  RealColumn get maxLon => real()();
  TextColumn get usfsName => text().nullable()(); // enrichment from EDW
  TextColumn get usfsNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Nodes kept only where they join two or more ways (graph vertices for routing).
class OsmNodes extends Table {
  IntColumn get id => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class OsmRelations extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get network => text().nullable()(); // lwn, rwn, nwn, iwn
  TextColumn get tagsJson => text()();
  TextColumn get memberWayIdsJson => text()(); // [123, 456]

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_pois_latlon', columns: {#lat, #lon})
class Pois extends Table {
  TextColumn get id => text()(); // "n123" or "w456"
  TextColumn get kind => text()(); // spring, peak, camp_site, trailhead...
  TextColumn get name => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get tagsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class CacheCells extends Table {
  TextColumn get cellKey => text()(); // "z10/163/357"
  TextColumn get dataset => text()(); // ways, pois, usfs, fires
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cellKey, dataset};
}

class Routes extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get geomJson => text()(); // full snapped polyline
  RealColumn get distanceM => real()();
  RealColumn get gainM => real()();
  RealColumn get lossM => real()();
  RealColumn get maxElevM => real()();
  RealColumn get minElevM => real()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RouteWaypoints extends Table {
  TextColumn get routeId => text().references(Routes, #id)();
  IntColumn get ordinal => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {routeId, ordinal};
}

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  IntColumn get movingSeconds => integer().withDefault(const Constant(0))();
  IntColumn get totalSeconds => integer().withDefault(const Constant(0))();
  RealColumn get gainM => real().withDefault(const Constant(0))();
  RealColumn get lossM => real().withDefault(const Constant(0))();
  RealColumn get packWeightKg => real().nullable()();
  RealColumn get calories => real().nullable()();
  TextColumn get linkedRouteId => text().nullable()();
  // For sync (tombstones + newest wins): the last genuine local edit time.
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
  // v5: battery at start and end, so Activity can show a measured "% per
  // hour" for each hike (local only, never sent anywhere).
  IntColumn get batteryStartPct => integer().nullable()();
  IntColumn get batteryEndPct => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TrackPoints extends Table {
  TextColumn get trackId => text().references(Tracks, #id)();
  IntColumn get seq => integer()();
  DateTimeColumn get t => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get gpsAltM => real().nullable()();
  RealColumn get demAltM => real().nullable()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();

  @override
  Set<Column> get primaryKey => {trackId, seq};
}

class OfflineRegions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get minLat => real()();
  RealColumn get minLon => real()();
  RealColumn get maxLat => real()();
  RealColumn get maxLon => real()();
  IntColumn get maplibreRegionId => integer().nullable()();
  TextColumn get styleKey => text()(); // outdoors, topo, satellite
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get status => integer()(); // 0 pending 1 downloading 2 done 3 error
  IntColumn get tileCount => integer().nullable()();
  IntColumn get bytes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ConditionsCache extends Table {
  TextColumn get key => text()(); // "fires:z10/163/357", "nws:46.46,-121.45"
  TextColumn get bodyJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// A deletion marker for sync (spec: sync-tombstones design). Travels in the
/// blob so other devices remove the record and do not re-add it. Newest wins:
/// a record with a lastModified newer than its tombstone's deletedAt lives.
class Tombstones extends Table {
  TextColumn get entityType => text()(); // "route" or "track"
  TextColumn get entityId => text()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

/// Trails the user saved from Explore (Addendum A7). The id is `r<relationId>`
/// or `w<firstWayId>`, stable across reloads of the underlying OSM data.
class FavoriteTrails extends Table {
  TextColumn get trailId => text()();
  TextColumn get name => text()();
  RealColumn get centerLat => real()();
  RealColumn get centerLon => real()();
  RealColumn get lengthM => real().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {trailId};
}

/// User-dropped pins (water, camp, hazard, viewpoint, parking, note), distinct
/// from the numbered route-shaping waypoints (Addendum A7). Optionally attached
/// to a route; deleting that route clears the attachment, it does not drop the
/// pin unless the user asks.
class UserWaypoints extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get kind =>
      text()(); // water, camp, hazard, viewpoint, parking, note
  TextColumn get name => text().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get routeId => text().nullable().references(Routes, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-made theme from the Theme Designer (Fix Pass 1 X4.4). Colors are
/// stored as ARGB ints. Mirrors CairnThemeSpec's nine editable colors.
class CustomThemes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isDark => boolean()();
  IntColumn get accent => integer()();
  IntColumn get background => integer()();
  IntColumn get surface => integer()();
  IntColumn get raised => integer()();
  IntColumn get outline => integer()();
  IntColumn get textPrimary => integer()();
  IntColumn get textSecondary => integer()();
  IntColumn get route => integer()();
  IntColumn get track => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    OsmWays,
    OsmNodes,
    OsmRelations,
    Pois,
    CacheCells,
    Routes,
    RouteWaypoints,
    Tracks,
    TrackPoints,
    OfflineRegions,
    ConditionsCache,
    Tombstones,
    FavoriteTrails,
    UserWaypoints,
    CustomThemes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// For tests: an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  /// Removes cached ways the trail parser no longer accepts (sidewalks,
  /// crossings, parking aisles, footway links); see the v6 migration.
  Future<void> deleteCachedStreetFurniture() async {
    for (final kind in ['sidewalk', 'crossing', 'access_aisle', 'link']) {
      await customStatement(
        'DELETE FROM osm_ways WHERE tags_json LIKE ?',
        ['%"footway":"$kind"%'],
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: sync support (tombstones + newest wins).
          if (from < 2) {
            await m.createTable(tombstones);
            await m.addColumn(tracks, tracks.lastModified);
          }
          // v3: saved trails and user waypoints (Phase R, Addendum A7). The
          // addendum wrote this as v2; the sync feature already claimed v2, so
          // these land in v3. Logged in docs/DECISIONS.md.
          if (from < 3) {
            await m.createTable(favoriteTrails);
            await m.createTable(userWaypoints);
          }
          // v4: Theme Designer custom themes (Fix Pass 1 X4.4).
          if (from < 4) {
            await m.createTable(customThemes);
          }
          // v5: per-hike battery drain (recording engine, spec Phase 6).
          if (from < 5) {
            await m.addColumn(tracks, tracks.batteryStartPct);
            await m.addColumn(tracks, tracks.batteryEndPct);
          }
          // v6: no schema change; drops cached sidewalks and crossings that
          // the trail query and parser no longer accept, so old cells do not
          // keep drawing street furniture as trails until their refresh.
          if (from < 6) await deleteCachedStreetFurniture();
        },
      );

  static LazyDatabase _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'cairn.sqlite')),
      );
    });
  }
}
