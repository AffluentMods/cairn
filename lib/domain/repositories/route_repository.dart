// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/route_plan.dart';

/// Saved routes, persisted locally (spec Section 7, Phase 3 and 4).
abstract interface class RouteRepository {
  /// Insert or update a route and its waypoints. Returns the route id.
  Future<String> save(SavedRoute route);

  /// All saved routes, newest first.
  Future<List<SavedRoute>> all();

  Future<SavedRoute?> byId(String id);

  Future<void> delete(String id);
}
