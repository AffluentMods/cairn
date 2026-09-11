// SPDX-License-Identifier: GPL-3.0-or-later

/// Terrain elevation, from cached DEM tiles (spec Section 5.7). Works offline
/// for areas already viewed or downloaded.
abstract interface class ElevationRepository {
  /// Elevations (meters) for each `[lat, lon]` point, with gaps from missing
  /// tiles filled from neighbors. Returns all zeros only if nothing is cached.
  Future<List<double>> elevationsAlong(List<List<double>> points);

  /// Elevation at one coordinate, or null if the tile is unavailable.
  Future<double?> elevationAt(double lat, double lon);
}
