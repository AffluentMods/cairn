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

/// Trails from OpenStreetMap, cached in the local database (spec Phase 2). The
/// contract is defined here in domain; the concrete implementation lives in data.
abstract interface class TrailRepository {
  /// Fetch any missing or stale z10 cells covering [bbox], ingest them, and
  /// record the cache. Renders from the DB regardless of network outcome.
  /// Cells nearest the bbox center go first; [isCancelled] is consulted
  /// between cells so a viewport that has moved on stops the loop.
  Future<TrailLoadResult> ensureArea(
    List<double> bbox, {
    bool force = false,
    bool Function()? isCancelled,
  });

  /// Trails whose bounding box intersects [bbox], read from the local DB.
  Future<List<Trail>> trailsInBbox(List<double> bbox, {int limit = 4000});

  /// A single trail by OSM way id.
  Future<Trail?> byId(int id);

  /// Name search over cached ways and route relations (Drift LIKE).
  Future<List<Trail>> searchByName(String query, {int limit = 30});

  /// Cached ways in [bbox] as routing graph input (node ids, coords, penalty).
  Future<List<RoutableWay>> routableWaysInBbox(List<double> bbox);
}
