// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/poi.dart';
import '../../domain/repositories/poi_repository.dart';
import '../db/app_database.dart';
import '../osm/overpass_parser.dart';
import '../sources/overpass_source.dart';

const _poiCellTtl = Duration(days: 30);
const _dataset = 'pois';

class PoiRepositoryImpl implements PoiRepository {
  PoiRepositoryImpl({required this.db, required this.overpass});

  final AppDatabase db;
  final OverpassSource overpass;

  @override
  Future<void> ensureArea(List<double> bbox) async {
    for (final cell in tilesForBbox(bbox, 10)) {
      if (await _isFresh(cell)) continue;
      await _ingestCell(cell);
    }
  }

  Future<bool> _isFresh(TileXY cell) async {
    final row = await (db.select(db.cacheCells)
          ..where(
              (t) => t.cellKey.equals(cell.key) & t.dataset.equals(_dataset)))
        .getSingleOrNull();
    if (row == null) return false;
    return DateTime.now().difference(row.fetchedAt) < _poiCellTtl;
  }

  Future<void> _ingestCell(TileXY cell) async {
    final bounds = tileBounds(cell);
    try {
      final json = await overpass.fetchPois(bounds);
      final pois = parseOverpassPois(json);
      await db.batch((b) {
        b.insertAllOnConflictUpdate(
          db.pois,
          pois
              .map(
                (p) => PoisCompanion.insert(
                  id: p.id,
                  kind: p.kind,
                  lat: p.lat,
                  lon: p.lon,
                  tagsJson: jsonEncode(p.tags),
                  name: Value(p.name),
                ),
              )
              .toList(),
        );
      });
      await db.into(db.cacheCells).insertOnConflictUpdate(
            CacheCellsCompanion.insert(
              cellKey: cell.key,
              dataset: _dataset,
              fetchedAt: DateTime.now(),
            ),
          );
    } on OverpassUnavailable {
      // Keep whatever is cached; POIs are non-critical.
    }
  }

  @override
  Future<List<PoiPoint>> poisInBbox(List<double> bbox,
      {int limit = 2000}) async {
    final rows = await (db.select(db.pois)
          ..where((t) =>
              t.lat.isBiggerOrEqualValue(bbox[0]) &
              t.lat.isSmallerOrEqualValue(bbox[2]) &
              t.lon.isBiggerOrEqualValue(bbox[1]) &
              t.lon.isSmallerOrEqualValue(bbox[3]))
          ..limit(limit))
        .get();
    return rows
        .map((r) => PoiPoint(
              id: r.id,
              kind: r.kind,
              lat: r.lat,
              lon: r.lon,
              name: r.name,
            ))
        .toList();
  }
}
