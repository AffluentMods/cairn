// SPDX-License-Identifier: GPL-3.0-or-later

/// A place from the Nominatim place search (spec Phase 2 search): a town,
/// park, peak or trailhead the map can fly to.
class PlaceHit {
  const PlaceHit({
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
    this.kind,
  });

  final String name;

  /// The full "Packwood, Lewis County, Washington, United States" line.
  final String displayName;
  final double lat;
  final double lon;
  final double south;
  final double north;
  final double west;
  final double east;

  /// Nominatim's type ("city", "peak", "park"), for a subtitle.
  final String? kind;

  /// True for an area worth framing rather than a point to zoom to.
  bool get isArea => (north - south) > 0.01 || (east - west) > 0.01;
}
