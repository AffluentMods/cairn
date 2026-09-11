// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/poi.dart';

/// Points of interest from OpenStreetMap, cached locally (spec Phase 2).
abstract interface class PoiRepository {
  /// Fetch any missing or stale z10 cells covering [bbox] and cache them.
  Future<void> ensureArea(List<double> bbox);

  /// POIs within [bbox] from the local DB.
  Future<List<PoiPoint>> poisInBbox(List<double> bbox, {int limit = 2000});
}
