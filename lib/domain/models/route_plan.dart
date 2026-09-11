// SPDX-License-Identifier: GPL-3.0-or-later

/// A waypoint in a saved route (spec Section 7).
class RouteWaypointModel {
  const RouteWaypointModel({
    required this.lat,
    required this.lon,
    this.label,
  });
  final double lat;
  final double lon;
  final String? label;
}

/// A saved, snapped route with its statistics (spec Section 7).
class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.geometry,
    required this.distanceM,
    required this.gainM,
    required this.lossM,
    required this.maxElevM,
    required this.minElevM,
    required this.waypoints,
    this.notes,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<List<double>> geometry; // [[lat, lon], ...]
  final double distanceM;
  final double gainM;
  final double lossM;
  final double maxElevM;
  final double minElevM;
  final String? notes;
  final List<RouteWaypointModel> waypoints;
}
