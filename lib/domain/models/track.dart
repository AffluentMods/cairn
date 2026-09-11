// SPDX-License-Identifier: GPL-3.0-or-later

/// One recorded GPS fix (spec Section 7).
class TrackPointData {
  const TrackPointData({
    required this.seq,
    required this.t,
    required this.lat,
    required this.lon,
    this.gpsAltM,
    this.demAltM,
    this.accuracyM,
    this.speedMps,
  });

  final int seq;
  final DateTime t;
  final double lat;
  final double lon;
  final double? gpsAltM;
  final double? demAltM;
  final double? accuracyM;
  final double? speedMps;

  /// Best available elevation: DEM when known, else smoothed GPS altitude.
  double? get elevM => demAltM ?? gpsAltM;
}

/// A recorded hike (spec Section 7): a track summary without its points.
class TrackSummary {
  const TrackSummary({
    required this.id,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.distanceM = 0,
    this.movingSeconds = 0,
    this.totalSeconds = 0,
    this.gainM = 0,
    this.lossM = 0,
    this.packWeightKg,
    this.calories,
    this.linkedRouteId,
  });

  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int movingSeconds;
  final int totalSeconds;
  final double gainM;
  final double lossM;
  final double? packWeightKg;
  final double? calories;
  final String? linkedRouteId;

  TrackSummary copyWith({
    String? name,
    DateTime? endedAt,
    double? distanceM,
    int? movingSeconds,
    int? totalSeconds,
    double? gainM,
    double? lossM,
    double? packWeightKg,
    double? calories,
    String? linkedRouteId,
  }) {
    return TrackSummary(
      id: id,
      name: name ?? this.name,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      gainM: gainM ?? this.gainM,
      lossM: lossM ?? this.lossM,
      packWeightKg: packWeightKg ?? this.packWeightKg,
      calories: calories ?? this.calories,
      linkedRouteId: linkedRouteId ?? this.linkedRouteId,
    );
  }
}
