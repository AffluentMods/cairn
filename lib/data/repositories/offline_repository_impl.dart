// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/repositories/conditions_repository.dart';
import '../../domain/repositories/offline_repository.dart';
import '../../domain/repositories/poi_repository.dart';
import '../../domain/repositories/trail_repository.dart';
import '../db/app_database.dart';
import '../sources/terrain_tile_source.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  OfflineRepositoryImpl({
    required this.db,
    required this.trails,
    required this.pois,
    required this.terrain,
    this.conditions,
  });

  final AppDatabase db;
  final TrailRepository trails;
  final PoiRepository pois;
  final TerrainTileSource terrain;

  /// Land boundaries (wilderness, forests) are cached through the conditions
  /// repository; optional so the repository stays constructible in tests.
  final ConditionsRepository? conditions;

  @override
  Future<List<OfflineRegionModel>> all() async {
    final rows = await (db.select(db.offlineRegions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<OfflineRegionModel?> byId(String id) async {
    final row = await (db.select(db.offlineRegions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<void> upsert(OfflineRegionModel r) async {
    await db.into(db.offlineRegions).insertOnConflictUpdate(
          OfflineRegionsCompanion.insert(
            id: r.id,
            name: r.name,
            minLat: r.minLat,
            minLon: r.minLon,
            maxLat: r.maxLat,
            maxLon: r.maxLon,
            styleKey: r.styleKeys.join(','),
            minZoom: r.minZoom,
            maxZoom: r.maxZoom,
            createdAt: r.createdAt,
            status: offlineStatusToInt(r.status),
            tileCount: Value(r.tileCount),
            bytes: Value(r.bytes),
          ),
        );
  }

  @override
  Future<void> updateStatus(
    String id,
    OfflineStatus status, {
    int? bytes,
    int? tileCount,
    int? maplibreRegionId,
  }) async {
    await (db.update(db.offlineRegions)..where((t) => t.id.equals(id))).write(
      OfflineRegionsCompanion(
        status: Value(offlineStatusToInt(status)),
        bytes: bytes == null ? const Value.absent() : Value(bytes),
        tileCount: tileCount == null ? const Value.absent() : Value(tileCount),
        maplibreRegionId: maplibreRegionId == null
            ? const Value.absent()
            : Value(maplibreRegionId),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.offlineRegions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> prefetchDataLayers(
    List<double> bbox, {
    bool force = false,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);
    await trails.ensureArea(bbox, force: force);
    onProgress?.call(0.25);
    await pois.ensureArea(bbox, force: force);
    onProgress?.call(0.4);
    // Wilderness and forest boundaries, so the land layer and its labels
    // work with no signal (30-day cache in the conditions repository).
    try {
      await conditions?.landInBbox(bbox);
    } on Exception {
      // Best effort: the basemap and trails are the point of a download.
    }
    onProgress?.call(0.5);
    // Terrain at z14 across the bbox, so elevation profiles work offline, and
    // at z11 to z13 so contour lines can be traced at every map zoom with
    // no signal (they come from the zoom one below the map's). One extra
    // tile east and south at each zoom: a tile's lines are traced with its
    // neighbors' edge samples.
    final tiles = <TileXY>[
      for (var z = contourMinTerrainZoom; z <= TerrainTileSource.zoom; z++)
        ...tilesForBbox(bbox, z).map((t) => TileXY(t.x + 1, t.y + 1, z)),
      for (var z = contourMinTerrainZoom; z <= TerrainTileSource.zoom; z++)
        ...tilesForBbox(bbox, z),
    ];
    final wanted = {for (final t in tiles) t.key: t};
    var i = 0;
    for (final t in wanted.values) {
      await terrain.tile(t);
      i++;
      onProgress?.call(0.5 + 0.5 * i / wanted.length);
    }
    onProgress?.call(1.0);
  }

  /// The widest terrain zoom contour lines use (lib/core/geo/contours.dart).
  static const contourMinTerrainZoom = 11;

  OfflineRegionModel _toModel(OfflineRegion row) => OfflineRegionModel(
        id: row.id,
        name: row.name,
        minLat: row.minLat,
        minLon: row.minLon,
        maxLat: row.maxLat,
        maxLon: row.maxLon,
        styleKeys: row.styleKey.split(',').where((s) => s.isNotEmpty).toList(),
        minZoom: row.minZoom,
        maxZoom: row.maxZoom,
        createdAt: row.createdAt,
        status: offlineStatusFromInt(row.status),
        tileCount: row.tileCount,
        bytes: row.bytes,
      );
}
