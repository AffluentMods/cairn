// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/forest_road.dart';

/// Forest Service roads and motorized trails from the Motor Vehicle Use Map,
/// cached per z10 cell in the local database like OSM trails.
abstract interface class RoadRepository {
  /// Fetch any missing or stale z10 cells covering [bbox], center first;
  /// [isCancelled] stops the loop between cells.
  Future<void> ensureArea(
    List<double> bbox, {
    bool force = false,
    bool Function()? isCancelled,
  });

  /// Segments whose bounding box intersects [bbox], roads before trails and
  /// longer segments first, from the local database.
  Future<List<ForestRoad>> roadsInBbox(List<double> bbox, {int limit = 3000});

  /// One segment by row id.
  Future<ForestRoad?> byId(String id);
}
