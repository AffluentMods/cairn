// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/forest_road.dart';
import '../../domain/repositories/road_repository.dart';
import '../db/app_database.dart';
import '../sources/usfs_source.dart';
import '../usfs/mvum_parser.dart';

/// The MVUM changes with each forest's annual map, so a cell is refetched
/// after 30 days (the trail cell TTL).
const _roadCellTtl = Duration(days: 30);
const _dataset = 'mvum';

class RoadRepositoryImpl implements RoadRepository {
  RoadRepositoryImpl({required this.db, required this.usfs});

  final AppDatabase db;
  final UsfsSource usfs;

  @override
  Future<void> ensureArea(
    List<double> bbox, {
    bool force = false,
    bool Function()? isCancelled,
  }) async {
    for (final cell in tilesForBboxCenterFirst(bbox, 10)) {
      if (isCancelled?.call() ?? false) break;
      if (!force && await _isFresh(cell)) continue;
      await _ingestCell(cell);
    }
  }

  Future<bool> _isFresh(TileXY cell) async {
    final row = await (db.select(db.cacheCells)
          ..where(
              (t) => t.cellKey.equals(cell.key) & t.dataset.equals(_dataset)))
        .getSingleOrNull();
    if (row == null) return false;
    return DateTime.now().difference(row.fetchedAt) < _roadCellTtl;
  }

  /// Fetches every page of roads and motorized trails for the cell. A cell is
  /// marked fresh only when both layers came through whole, so a dropped
  /// connection retries next time rather than leaving half a forest.
  Future<void> _ingestCell(TileXY cell) async {
    final bounds = tileBounds(cell);
    final rows = <UsfsRoadsCompanion>[];
    for (final trails in [false, true]) {
      var offset = 0;
      while (true) {
        final raw =
            await usfs.fetchMvumPage(bounds, trails: trails, offset: offset);
        if (raw == null) return;
        final MvumPage page;
        try {
          page = await parseMvumAsync(raw, trails: trails);
        } on FormatException {
          return; // an error page, not GeoJSON
        }
        rows.addAll(page.roads.map(_companion));
        if (!page.exceeded || page.roads.isEmpty) break;
        offset += 1000;
      }
    }
    await db.batch((b) => b.insertAllOnConflictUpdate(db.usfsRoads, rows));
    await db.into(db.cacheCells).insertOnConflictUpdate(
          CacheCellsCompanion.insert(
            cellKey: cell.key,
            dataset: _dataset,
            fetchedAt: DateTime.now(),
          ),
        );
  }

  UsfsRoadsCompanion _companion(ForestRoad r) {
    var minLat = r.geometry.first[0], maxLat = r.geometry.first[0];
    var minLon = r.geometry.first[1], maxLon = r.geometry.first[1];
    for (final p in r.geometry) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    return UsfsRoadsCompanion.insert(
      id: r.id,
      routeId: r.routeId,
      number: r.number,
      name: Value(r.name),
      kind: r.kind,
      symbol: r.symbol,
      symbolName: Value(r.symbolName),
      seasonal: Value(r.seasonal),
      surface: Value(r.surface),
      maintLevel: Value(r.maintLevel),
      accessJson: Value(jsonEncode({
        for (final a in r.access) a.vehicle: a.dates,
      })),
      lengthMi: Value(r.lengthMi),
      geomJson: jsonEncode(r.geometry),
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
    );
  }

  @override
  Future<List<ForestRoad>> roadsInBbox(List<double> bbox,
      {int limit = 3000}) async {
    final rows = await (db.select(db.usfsRoads)
          ..where((t) =>
              t.minLat.isSmallerOrEqualValue(bbox[2]) &
              t.maxLat.isBiggerOrEqualValue(bbox[0]) &
              t.minLon.isSmallerOrEqualValue(bbox[3]) &
              t.maxLon.isBiggerOrEqualValue(bbox[1]))
          ..orderBy([
            (t) => OrderingTerm(expression: t.kind),
            (t) =>
                OrderingTerm(expression: t.lengthMi, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<ForestRoad?> byId(String id) async {
    final row = await (db.select(db.usfsRoads)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  ForestRoad _toModel(UsfsRoad row) {
    final geom = (jsonDecode(row.geomJson) as List)
        .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
        .toList();
    final access = (jsonDecode(row.accessJson) as Map).cast<String, dynamic>();
    return ForestRoad(
      id: row.id,
      routeId: row.routeId,
      number: row.number,
      name: row.name,
      kind: row.kind,
      symbol: row.symbol,
      symbolName: row.symbolName,
      seasonal: row.seasonal,
      surface: row.surface,
      maintLevel: row.maintLevel,
      access: [
        for (final v in mvumVehicleFields.values)
          if (access[v] != null)
            RoadAccess(vehicle: v, dates: access[v].toString()),
      ],
      lengthMi: row.lengthMi,
      geometry: geom,
    );
  }
}
