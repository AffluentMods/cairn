// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/trail.dart';
import '../../domain/repositories/trail_repository.dart';
import '../../domain/usecases/route_between_waypoints.dart';
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
  Future<TrailLoadResult> ensureArea(
    List<double> bbox, {
    bool force = false,
    bool Function()? isCancelled,
    TrailCellProgress? onCell,
  }) async {
    final cells = tilesForBboxCenterFirst(bbox, 10);
    // Work out up front which cells need a query, so [onCell] can report a
    // real total from the first moment (the UI shows "Loading trails 0/5"
    // while the first Overpass request is still in flight).
    final fresh = force ? const <String>{} : await _freshKeys(cells);
    final todo = [
      for (final c in cells)
        if (!fresh.contains(c.key)) c
    ];
    if (todo.isEmpty) {
      return const TrailLoadResult(networkError: false, cellsFetched: 0);
    }
    if (onCell != null) await onCell(0, todo.length, false);
    var networkError = false;
    var fetched = 0;
    var done = 0;
    for (final cell in todo) {
      if (isCancelled?.call() ?? false) break;
      final ok = await _ingestCell(cell);
      if (ok) {
        fetched++;
      } else {
        networkError = true;
      }
      done++;
      if (onCell != null) await onCell(done, todo.length, ok);
    }
    return TrailLoadResult(networkError: networkError, cellsFetched: fetched);
  }

  /// The keys of [cells] cached within the TTL, in one query.
  Future<Set<String>> _freshKeys(List<TileXY> cells) async {
    if (cells.isEmpty) return const {};
    final cutoff = DateTime.now().subtract(_trailCellTtl);
    final rows = await (db.select(db.cacheCells)
          ..where((t) =>
              t.dataset.equals(_dataset) &
              t.cellKey.isIn([for (final c in cells) c.key]) &
              t.fetchedAt.isBiggerThanValue(cutoff)))
        .get();
    return {for (final r in rows) r.cellKey};
  }

  /// Returns true on success, false if the network was unavailable or the
  /// response could not be parsed.
  Future<bool> _ingestCell(TileXY cell) async {
    final bounds = tileBounds(cell);
    try {
      final raw = await overpass.fetchWays(bounds);
      // Decode and parse off the UI isolate (Fix Pass 1 X1.3.1, H3). The
      // worker call lives next to the parser: a closure built here would
      // capture this repository and its database, which cannot cross an
      // isolate boundary.
      final parsed = await parseOverpassWaysAsync(raw);
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
    } on FormatException {
      // A mirror returned something that was not JSON (an error page); treat
      // the cell as unfetched rather than crashing.
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
        nodeIdsJson: Value(jsonEncode(w.nodeIds)),
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
  Future<List<Trail>> trailsInBbox(
    List<double> bbox, {
    int limit = 4000,
    bool namedOnly = false,
    bool excludeTracks = false,
  }) async {
    final query = db.select(db.osmWays)
      ..where((t) {
        var clause = t.minLat.isSmallerOrEqualValue(bbox[2]) &
            t.maxLat.isBiggerOrEqualValue(bbox[0]) &
            t.minLon.isSmallerOrEqualValue(bbox[3]) &
            t.maxLon.isBiggerOrEqualValue(bbox[1]);
        if (namedOnly) {
          clause = clause & t.name.isNotNull() & t.name.equals('').not();
        }
        if (excludeTracks) clause = clause & t.highway.equals('track').not();
        return clause;
      })
      // Named first, then longest: past [limit], what drops is the short
      // unnamed connectors, never a named trail.
      ..orderBy([
        (t) => OrderingTerm(expression: t.name.isNull()),
        (t) => OrderingTerm(expression: t.lengthM, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    final rows = await query.get();
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

  @override
  Future<List<RoutableWay>> routableWaysInBbox(List<double> bbox) async {
    final rows = await (db.select(db.osmWays)
          ..where(
            (t) =>
                t.minLat.isSmallerOrEqualValue(bbox[2]) &
                t.maxLat.isBiggerOrEqualValue(bbox[0]) &
                t.minLon.isSmallerOrEqualValue(bbox[3]) &
                t.maxLon.isBiggerOrEqualValue(bbox[1]),
          ))
        .get();
    final out = <RoutableWay>[];
    for (final row in rows) {
      final coords = (jsonDecode(row.geomJson) as List)
          .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
          .toList();
      final nodeIds = (jsonDecode(row.nodeIdsJson) as List)
          .map((e) => (e as num).toInt())
          .toList();
      // Older cached rows may predate node ids; skip them for routing.
      if (nodeIds.length != coords.length || nodeIds.length < 2) continue;
      final tags = (jsonDecode(row.tagsJson) as Map).cast<String, dynamic>();
      out.add(
        RoutableWay(
          id: row.id,
          nodeIds: nodeIds,
          coords: coords,
          penalty: routePenalty(
            informal: row.informal,
            sacScale: row.sacScale,
            access: tags['access'] as String?,
          ),
        ),
      );
    }
    return out;
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
