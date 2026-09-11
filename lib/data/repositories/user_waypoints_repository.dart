// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// User-dropped pins, backed by the [UserWaypoints] table (Addendum A4.5 / A7).
class UserWaypointsRepository {
  UserWaypointsRepository(this._db);

  final AppDatabase _db;

  Future<List<UserWaypoint>> all() => (_db.select(_db.userWaypoints)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Stream<List<UserWaypoint>> watchAll() => (_db.select(_db.userWaypoints)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<UserWaypoint>> forRoute(String routeId) =>
      (_db.select(_db.userWaypoints)..where((t) => t.routeId.equals(routeId)))
          .get();

  Future<void> upsert(UserWaypointsCompanion waypoint) =>
      _db.into(_db.userWaypoints).insertOnConflictUpdate(waypoint);

  Future<void> delete(String id) =>
      (_db.delete(_db.userWaypoints)..where((t) => t.id.equals(id))).go();

  /// Clear the route link on every pin attached to [routeId]. Used when a route
  /// is deleted but its standalone pins should survive (Addendum A7).
  Future<void> detachRoute(String routeId) =>
      (_db.update(_db.userWaypoints)..where((t) => t.routeId.equals(routeId)))
          .write(const UserWaypointsCompanion(routeId: Value(null)));

  /// Delete every pin attached to [routeId] (the "Also delete pins" path).
  Future<void> deleteForRoute(String routeId) =>
      (_db.delete(_db.userWaypoints)..where((t) => t.routeId.equals(routeId)))
          .go();
}
