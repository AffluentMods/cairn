// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/trail.dart';
import '../../domain/repositories/trail_repository.dart';
import '../db/app_database.dart';
import '../osm/overpass_parser.dart';
import '../sources/overpass_source.dart';
import '../sources/usfs_source.dart';

/// How long a cached trail cell stays fresh (spec Section 7).
const _trailCellTtl = Duration(days: 30);
const _dataset = 'ways';

class TrailRepositoryImpl implements TrailRepository {
  TrailRepositoryImpl({
    required this.db,
    required this.overpass,
    required this.usfs,
  });

  final AppDatabase db;
  final OverpassSource overpass;
  final UsfsSource usfs;

  @override
  Future<TrailLoadResult> ensureArea(List<double> bbox) async {
    final cells = tilesForBbox(bbox, 10);
    var networkError = false;
    var fetched = 0;
    for (final cell in cells) {
      if (await _isFresh(cell)) continue;
      final ok = await _ingestCell(cell);
      if (ok) {
        fetched++;
      } else {
        networkError = true;
      }
    }
    return TrailLoadResult(networkError: networkError, cellsFetched: fetched);
  }

  Future<bool> _isFresh(TileXY cell) async {
    final row = await (db.select(db.cacheCells)
          ..where(
              (t) => t.cellKey.equals(cell.key) & t.dataset.equals(_dataset)))
        .getSingleOrNull();
    if (row == null) return false;
    return DateTime.now().difference(row.fetchedAt) < _trailCellTtl;
  }

  /// Returns true on success, false if the network was unavailable.
  Future<bool> _ingestCell(TileXY cell) async {
    final bounds = tileBounds(cell);
    try {
      final json = await overpass.fetchWays(bounds);
      final parsed = parseOverpassWays(json);
      await db.batch((b) {
        b.insertAllOnConflictUpdate(
          db.osmWays,
          parsed.ways.map(_wayCompanion).toList(),
        );
        b.insertAllOnConflictUpdate(
          db.osmNodes,
          parsed.graphNodes
              .map((n) => OsmNodesCompanion.insert(
                  id: Value(n.id), lat: n.lat, lon: n.lon))
              .toList(),
        );
        b.insertAllOnConflictUpdate(
          db.osmRelations,
          parsed.relations.map(_relationCompanion).toList(),
        );
      });
      await _markFresh(cell);
      await _enrichUsfs(bounds); // best effort, never throws
      return true;
    } on OverpassUnavailable {
      return false;
    }
  }

  Future<void> _markFresh(TileXY cell) async {
    await db.into(db.cacheCells).insertOnConflictUpdate(
          CacheCellsCompanion.insert(
            cellKey: cell.key,
            dataset: _dataset,
            fetchedAt: DateTime.now(),
          ),
        );
  }

  OsmWaysCompanion _wayCompanion(ParsedWay w) => OsmWaysCompanion.insert(
        id: Value(w.id),
        highway: w.highway,
        tagsJson: jsonEncode(w.tags),
        geomJson: jsonEncode(w.geometry),
        firstNodeId: w.firstNodeId,
        lastNodeId: w.lastNodeId,
        lengthM: w.lengthM,
        minLat: w.minLat,
        minLon: w.minLon,
        maxLat: w.maxLat,
        maxLon: w.maxLon,
        name: Value(w.name),
        sacScale: Value(w.sacScale),
        trailVisibility: Value(w.trailVisibility),
        surface: Value(w.surface),
        informal: Value(w.informal),
      );

  OsmRelationsCompanion _relationCompanion(ParsedRelation r) =>
      OsmRelationsCompanion.insert(
        id: Value(r.id),
        name: Value(r.name),
        network: Value(r.network),
        tagsJson: jsonEncode(r.tags),
        memberWayIdsJson: jsonEncode(r.memberWayIds),
      );

  /// Name-based enrichment: match cached ways to USFS trail names for the same
  /// bbox and copy the official name and number. A proximity/geometry match
  /// (spec Section 8) is a later improvement; this is cheap and non-blocking.
  Future<void> _enrichUsfs(List<double> bounds) async {
    try {
      final geo = await usfs.fetchTrails(bounds);
      final features =
          (geo?['features'] as List?)?.cast<Map<String, dynamic>>();
      if (features == null || features.isEmpty) return;
      final byName = <String, ({String name, String? number})>{};
      for (final f in features) {
        final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
        final name =
            pickField(props, ['TRAIL_NAME', 'NAME', 'trail_name'])?.toString();
        if (name == null || name.trim().isEmpty) continue;
        final number =
            pickField(props, ['TRAIL_NO', 'TRAIL_CN', 'trail_no'])?.toString();
        byName[_norm(name)] = (name: name, number: number);
      }
      if (byName.isEmpty) return;

      final ways = await (db.select(db.osmWays)
            ..where((t) =>
                t.minLat.isSmallerOrEqualValue(bounds[2]) &
                t.maxLat.isBiggerOrEqualValue(bounds[0]) &
                t.minLon.isSmallerOrEqualValue(bounds[3]) &
                t.maxLon.isBiggerOrEqualValue(bounds[1])))
          .get();
      for (final way in ways) {
        final name = way.name;
        if (name == null) continue;
        final match = byName[_norm(name)];
        if (match == null) continue;
        await (db.update(db.osmWays)..where((t) => t.id.equals(way.id))).write(
          OsmWaysCompanion(
            usfsName: Value(match.name),
            usfsNumber: Value(match.number),
          ),
        );
      }
    } catch (_) {
      // Enrichment is optional; a failure never breaks trail loading.
    }
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'#?\d+'), '')
      .replaceAll(RegExp(r'\btrail\b'), '')
      .replaceAll(RegExp(r'[^a-z ]'), '')
      .trim();

  @override
  Future<List<Trail>> trailsInBbox(List<double> bbox,
      {int limit = 4000}) async {
    final rows = await (db.select(db.osmWays)
          ..where((t) =>
              t.minLat.isSmallerOrEqualValue(bbox[2]) &
              t.maxLat.isBiggerOrEqualValue(bbox[0]) &
              t.minLon.isSmallerOrEqualValue(bbox[3]) &
              t.maxLon.isBiggerOrEqualValue(bbox[1]))
          ..limit(limit))
        .get();
    return rows.map(_toTrail).toList();
  }

  @override
  Future<Trail?> byId(int id) async {
    final row = await (db.select(db.osmWays)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toTrail(row);
  }

  @override
  Future<List<Trail>> searchByName(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await (db.select(db.osmWays)
          ..where((t) => t.name.like('%$q%'))
          ..limit(limit))
        .get();
    return rows.map(_toTrail).toList();
  }

  Trail _toTrail(OsmWay row) {
    final geom = (jsonDecode(row.geomJson) as List)
        .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
        .toList();
    return Trail(
      id: row.id,
      highway: row.highway,
      lengthM: row.lengthM,
      informal: row.informal,
      name: row.name,
      sacScale: row.sacScale,
      trailVisibility: row.trailVisibility,
      surface: row.surface,
      usfsName: row.usfsName,
      usfsNumber: row.usfsNumber,
      geometry: geom,
    );
  }
}
