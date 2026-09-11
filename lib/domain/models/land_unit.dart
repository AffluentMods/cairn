// SPDX-License-Identifier: GPL-3.0-or-later

/// The kind of land management unit (spec Phase 7).
enum LandKind { wilderness, forest, nationalPark, statePark }

/// A land management polygon: wilderness, national forest, or park (spec Phase
/// 7). Geometry is a list of rings ([lat, lon] points).
class LandUnit {
  const LandUnit({
    required this.kind,
    required this.name,
    this.polygons = const [],
  });

  final LandKind kind;
  final String name;
  final List<List<List<double>>> polygons;

  /// The map fill/stroke color for this kind (hex), used by the land layer.
  String get strokeHex => switch (kind) {
        LandKind.wilderness => '#3EC46D',
        LandKind.forest => '#6B4F2A',
        LandKind.nationalPark => '#3FB8AF',
        LandKind.statePark => '#9B59B6',
      };
}
