// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/route_plan.dart';
import '../../domain/repositories/route_repository.dart';
import '../db/app_database.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Future<String> save(SavedRoute route) async {
    await db.transaction(() async {
      await db.into(db.routes).insertOnConflictUpdate(
            RoutesCompanion.insert(
              id: route.id,
              name: route.name,
              createdAt: route.createdAt,
              updatedAt: route.updatedAt,
              geomJson: jsonEncode(route.geometry),
              distanceM: route.distanceM,
              gainM: route.gainM,
              lossM: route.lossM,
              maxElevM: route.maxElevM,
              minElevM: route.minElevM,
              notes: Value(route.notes),
            ),
          );
      // Replace waypoints.
      await (db.delete(db.routeWaypoints)
            ..where((t) => t.routeId.equals(route.id)))
          .go();
      await db.batch((b) {
        for (var i = 0; i < route.waypoints.length; i++) {
          final w = route.waypoints[i];
          b.insert(
            db.routeWaypoints,
            RouteWaypointsCompanion.insert(
              routeId: route.id,
              ordinal: i,
              lat: w.lat,
              lon: w.lon,
              label: Value(w.label),
            ),
          );
        }
      });
    });
    return route.id;
  }

  @override
  Future<List<SavedRoute>> all() async {
    final rows = await (db.select(db.routes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    final out = <SavedRoute>[];
    for (final row in rows) {
      out.add(await _hydrate(row));
    }
    return out;
  }

  @override
  Future<SavedRoute?> byId(String id) async {
    final row = await (db.select(db.routes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  @override
  Future<void> delete(String id) async {
    await db.transaction(() async {
      await (db.delete(db.routeWaypoints)..where((t) => t.routeId.equals(id)))
          .go();
      await (db.delete(db.routes)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<SavedRoute> _hydrate(Route row) async {
    final wpRows = await (db.select(db.routeWaypoints)
          ..where((t) => t.routeId.equals(row.id))
          ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
        .get();
    final geom = (jsonDecode(row.geomJson) as List)
        .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
        .toList();
    return SavedRoute(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      geometry: geom,
      distanceM: row.distanceM,
      gainM: row.gainM,
      lossM: row.lossM,
      maxElevM: row.maxElevM,
      minElevM: row.minElevM,
      notes: row.notes,
      waypoints: [
        for (final w in wpRows)
          RouteWaypointModel(lat: w.lat, lon: w.lon, label: w.label),
      ],
    );
  }
}
