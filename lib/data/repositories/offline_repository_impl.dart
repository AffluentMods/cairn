// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/offline_region.dart';
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
  });

  final AppDatabase db;
  final TrailRepository trails;
  final PoiRepository pois;
  final TerrainTileSource terrain;

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
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);
    await trails.ensureArea(bbox);
    onProgress?.call(0.3);
    await pois.ensureArea(bbox);
    onProgress?.call(0.5);
    // Terrain at z14 across the bbox, so elevation profiles work offline.
    final tiles = tilesForBbox(bbox, TerrainTileSource.zoom);
    for (var i = 0; i < tiles.length; i++) {
      await terrain.tile(tiles[i]);
      onProgress?.call(0.5 + 0.5 * (i + 1) / tiles.length);
    }
    onProgress?.call(1.0);
  }

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
