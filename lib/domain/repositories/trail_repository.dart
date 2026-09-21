// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/trail.dart';
import '../usecases/route_between_waypoints.dart';

/// Outcome of ensuring an area is cached.
class TrailLoadResult {
  const TrailLoadResult(
      {required this.networkError, required this.cellsFetched});

  /// True if at least one cell could not be fetched (Overpass down). The map
  /// still renders whatever is cached; the UI shows a non-blocking banner.
  final bool networkError;
  final int cellsFetched;
}

/// Progress of a [TrailRepository.ensureArea] pass. [total] counts only the
/// cells that need a query (fresh cells are skipped); it is called once with
/// [done] 0 before the first query, then after each cell, with [fetched] true
/// when that cell's trails just landed in the database (false when its query
/// failed). Lets a caller show progress and paint trails cell by cell instead
/// of after the whole pass. Never called when every cell is already fresh.
typedef TrailCellProgress = Future<void> Function(
    int done, int total, bool fetched);

/// Trails from OpenStreetMap, cached in the local database (spec Phase 2). The
/// contract is defined here in domain; the concrete implementation lives in data.
abstract interface class TrailRepository {
  /// Fetch any missing or stale z10 cells covering [bbox], ingest them, and
  /// record the cache. Renders from the DB regardless of network outcome.
  /// Cells nearest the bbox center go first; [isCancelled] is consulted
  /// between cells so a viewport that has moved on stops the loop, and
  /// [onCell] runs after every cell.
  Future<TrailLoadResult> ensureArea(
    List<double> bbox, {
    bool force = false,
    bool Function()? isCancelled,
    TrailCellProgress? onCell,
  });

  /// Trails whose bounding box intersects [bbox], read from the local DB.
  /// Named ways come first, then longer ones, so [limit] drops short unnamed
  /// connectors before anything a hiker would look for. [namedOnly] and
  /// [excludeTracks] filter in SQL, so a wide view is not cut short by rows it
  /// would discard anyway.
  Future<List<Trail>> trailsInBbox(
    List<double> bbox, {
    int limit = 4000,
    bool namedOnly = false,
    bool excludeTracks = false,
  });

  /// A single trail by OSM way id.
  Future<Trail?> byId(int id);

  /// Name search over cached ways and route relations (Drift LIKE).
  Future<List<Trail>> searchByName(String query, {int limit = 30});

  /// Cached ways in [bbox] as routing graph input (node ids, coords, penalty).
  Future<List<RoutableWay>> routableWaysInBbox(List<double> bbox);
}
