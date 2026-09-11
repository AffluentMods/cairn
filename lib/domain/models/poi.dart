// SPDX-License-Identifier: GPL-3.0-or-later

/// A point of interest for the map: spring, peak, campsite, trailhead, water,
/// and so on (spec Section 8, Phase 2). Plain and immutable; the map layer maps
/// [kind] to an icon.
class PoiPoint {
  const PoiPoint({
    required this.id,
    required this.kind,
    required this.lat,
    required this.lon,
    this.name,
  });

  final String id; // "n123" or "w456"
  final String kind;
  final double lat;
  final double lon;
  final String? name;
}
