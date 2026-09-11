// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';

/// A trail longer than this navigates as a section, not the whole line.
const double _wholeTrailMaxM = 24140; // 15 mi

/// Picks the section of a trail to navigate (Fix Pass 1 X2.2): the whole trail
/// when it is under 15 mi, otherwise the run of vertices inside the current
/// viewport expanded by 25%. The result is oriented to start at the end nearest
/// the user (so the route leads away from them); with no user fix the original
/// order is kept.
///
/// [geometry] and the result are `[lat, lon]` pairs; [viewportBbox] is
/// `[minLat, minLon, maxLat, maxLon]`.
List<List<double>> selectRouteSection(
  List<List<double>> geometry, {
  List<double>? viewportBbox,
  double? userLat,
  double? userLon,
}) {
  if (geometry.length < 2) return geometry;

  var section = geometry;
  if (polylineLengthMeters(geometry) > _wholeTrailMaxM && viewportBbox != null) {
    final clipped = _clipToViewport(geometry, viewportBbox);
    if (clipped.length >= 2) section = clipped;
  }

  if (userLat != null && userLon != null && section.length >= 2) {
    final toStart =
        haversineMeters(userLat, userLon, section.first[0], section.first[1]);
    final toEnd =
        haversineMeters(userLat, userLon, section.last[0], section.last[1]);
    if (toEnd < toStart) section = section.reversed.toList();
  }
  return section;
}

/// The contiguous run of vertices inside [bbox] expanded by 25% of its span,
/// plus one vertex of margin on each side for continuity. Empty if none fall
/// inside.
List<List<double>> _clipToViewport(
  List<List<double>> geom,
  List<double> bbox,
) {
  final padLat = (bbox[2] - bbox[0]) * 0.25;
  final padLon = (bbox[3] - bbox[1]) * 0.25;
  final minLat = bbox[0] - padLat;
  final maxLat = bbox[2] + padLat;
  final minLon = bbox[1] - padLon;
  final maxLon = bbox[3] + padLon;
  bool inside(List<double> p) =>
      p[0] >= minLat && p[0] <= maxLat && p[1] >= minLon && p[1] <= maxLon;

  var first = -1;
  var last = -1;
  for (var i = 0; i < geom.length; i++) {
    if (inside(geom[i])) {
      if (first < 0) first = i;
      last = i;
    }
  }
  if (first < 0) return const [];
  first = (first - 1).clamp(0, geom.length - 1);
  last = (last + 1).clamp(0, geom.length - 1);
  return geom.sublist(first, last + 1);
}

/// Whether the route's start is more than a mile from the user, so Navigate can
/// warn that the trailhead is far and offer directions (Fix Pass 1 X2.2).
bool routeStartIsFar(
  List<List<double>> section, {
  required double? userLat,
  required double? userLon,
}) {
  if (section.isEmpty || userLat == null || userLon == null) return false;
  return haversineMeters(userLat, userLon, section.first[0], section.first[1]) >
      1609; // 1 mi
}
