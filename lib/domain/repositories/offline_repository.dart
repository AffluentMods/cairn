// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/offline_region.dart';

/// Offline regions and their downloaded data (spec Phase 5). The basemap tile
/// download itself runs through the MapLibre controller in the UI; this handles
/// the region records and the trail, POI, and terrain prefetch.
abstract interface class OfflineRepository {
  Future<List<OfflineRegionModel>> all();

  Future<OfflineRegionModel?> byId(String id);

  /// Insert a region record (status pending).
  Future<void> upsert(OfflineRegionModel region);

  Future<void> updateStatus(
    String id,
    OfflineStatus status, {
    int? bytes,
    int? tileCount,
    int? maplibreRegionId,
  });

  Future<void> delete(String id);

  /// Fetch trail cells, POI cells, and terrain tiles for the bbox so planning
  /// and elevation work offline inside it. [onProgress] reports 0..1.
  Future<void> prefetchDataLayers(
    List<double> bbox, {
    void Function(double progress)? onProgress,
  });
}
