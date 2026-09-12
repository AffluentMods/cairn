// SPDX-License-Identifier: GPL-3.0-or-later

/// A wildfire or prescribed burn from NIFC WFIGS (spec Phase 7). Geometry is a
/// list of rings ([lat, lon] points); points-only incidents have an empty
/// [polygons] and a [lat]/[lon].
class FireIncident {
  const FireIncident({
    required this.id,
    required this.name,
    this.acres,
    this.percentContained,
    this.discoveredAt,
    this.modifiedAt,
    this.behavior,
    this.prescribed = false,
    this.lat,
    this.lon,
    this.polygons = const [],
    this.unitId,
    this.irwinId,
    this.distanceToRouteM,
    this.crossesRoute = false,
  });

  final String id;
  final String name;
  final double? acres;
  final int? percentContained;
  final DateTime? discoveredAt;
  final DateTime? modifiedAt;
  final String? behavior;
  final bool prescribed;
  final double? lat;
  final double? lon;
  final List<List<List<double>>> polygons; // [ring][point][lat,lon]

  /// WFIGS POOProtectingUnit ("WAGPF"), the prefix InciWeb titles use.
  final String? unitId;

  /// IRWIN id shared by a perimeter and its incident point.
  final String? irwinId;

  /// Filled by the route-proximity use case.
  final double? distanceToRouteM;
  final bool crossesRoute;

  bool get isPerimeter => polygons.isNotEmpty;

  FireIncident withProximity({
    required double distanceM,
    required bool crosses,
  }) {
    return FireIncident(
      id: id,
      name: name,
      acres: acres,
      percentContained: percentContained,
      discoveredAt: discoveredAt,
      modifiedAt: modifiedAt,
      behavior: behavior,
      prescribed: prescribed,
      lat: lat,
      lon: lon,
      polygons: polygons,
      unitId: unitId,
      irwinId: irwinId,
      distanceToRouteM: distanceM,
      crossesRoute: crosses,
    );
  }
}
