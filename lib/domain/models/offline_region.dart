// SPDX-License-Identifier: GPL-3.0-or-later

/// Download lifecycle of an offline region (spec Section 7: status column).
enum OfflineStatus { pending, downloading, done, error }

OfflineStatus offlineStatusFromInt(int v) => switch (v) {
      1 => OfflineStatus.downloading,
      2 => OfflineStatus.done,
      3 => OfflineStatus.error,
      _ => OfflineStatus.pending,
    };

int offlineStatusToInt(OfflineStatus s) => switch (s) {
      OfflineStatus.pending => 0,
      OfflineStatus.downloading => 1,
      OfflineStatus.done => 2,
      OfflineStatus.error => 3,
    };

/// A saved offline region (spec Section 7).
class OfflineRegionModel {
  const OfflineRegionModel({
    required this.id,
    required this.name,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    required this.styleKeys,
    required this.minZoom,
    required this.maxZoom,
    required this.createdAt,
    required this.status,
    this.tileCount,
    this.bytes,
    this.overlayKeys = const [],
  });

  final String id;
  final String name;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;

  /// The style keys downloaded, e.g. ["outdoors", "topo"].
  final List<String> styleKeys;
  final int minZoom;
  final int maxZoom;
  final DateTime createdAt;
  final OfflineStatus status;
  final int? tileCount;
  final int? bytes;

  /// Raster overlay keys downloaded with the region (Official trails, MVUM,
  /// slope, ...), served offline by the tile proxy.
  final List<String> overlayKeys;

  List<double> get bbox => [minLat, minLon, maxLat, maxLon];
}
