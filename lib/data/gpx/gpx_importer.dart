// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/geo/elevation_stats.dart';
import '../../core/geo/haversine.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/models/track.dart';
import '../../domain/repositories/elevation_repository.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/usecases/compute_route_stats.dart';
import '../db/app_database.dart';
import '../repositories/user_waypoints_repository.dart';
import 'gpx_codec.dart';

/// How many items a GPX import produced.
class GpxImportSummary {
  const GpxImportSummary({
    required this.routes,
    required this.tracks,
    this.waypoints = 0,
  });
  final int routes;
  final int tracks;

  /// User pins from `<wpt>` elements, attached to the imported route.
  final int waypoints;
  int get total => routes + tracks;
}

/// Turns parsed GPX into saved routes and tracks, computing statistics with DEM
/// elevation (spec Phase 4). GPX `<ele>` is kept as gpsAltM but not trusted for
/// gain. `<wpt>` pins become user waypoints attached to the file's route (or
/// standalone pins when the file has none).
class GpxImporter {
  GpxImporter({
    required this.routes,
    required this.tracks,
    required this.elevation,
    this.userWaypoints,
  });

  final RouteRepository routes;
  final TrackRepository tracks;
  final ElevationRepository elevation;
  final UserWaypointsRepository? userWaypoints;

  static const _uuid = Uuid();

  /// [fallbackName] names a route or track whose file carries no name; the
  /// caller passes a localized string (the file name in practice).
  Future<GpxImportSummary> import(
    GpxImport data, {
    required String fallbackName,
  }) async {
    var routeCount = 0;
    var trackCount = 0;
    String? firstRouteId;

    for (final t in data.tracks) {
      await _saveTrack(t, fallbackName);
      trackCount++;
    }
    for (final r in data.routes) {
      final id = await _saveRoute(r, fallbackName);
      firstRouteId ??= id;
      routeCount++;
    }

    var pinCount = 0;
    final pins = userWaypoints;
    if (pins != null && data.waypoints.isNotEmpty) {
      final now = DateTime.now();
      for (final w in data.waypoints) {
        await pins.upsert(UserWaypointsCompanion.insert(
          id: _uuid.v4(),
          kind: w.kind ?? 'note',
          name: Value(w.name),
          note: Value(w.note),
          lat: w.lat,
          lon: w.lon,
          routeId: Value(firstRouteId),
          createdAt: now,
        ));
        pinCount++;
      }
    }
    return GpxImportSummary(
      routes: routeCount,
      tracks: trackCount,
      waypoints: pinCount,
    );
  }

  Future<String> _saveRoute(GpxRouteData data, String fallbackName) async {
    final geometry = [
      for (final p in data.points) [p.lat, p.lon],
    ];
    final stats = await computeRouteStats(geometry, elevation);
    final now = DateTime.now();
    return routes.save(
      SavedRoute(
        id: _uuid.v4(),
        name: data.name ?? fallbackName,
        createdAt: now,
        updatedAt: now,
        geometry: geometry,
        distanceM: stats.distanceM,
        gainM: stats.gainM,
        lossM: stats.lossM,
        maxElevM: stats.maxElevM,
        minElevM: stats.minElevM,
        waypoints: [
          for (final p in data.points)
            RouteWaypointModel(lat: p.lat, lon: p.lon),
        ],
      ),
    );
  }

  Future<void> _saveTrack(GpxTrackData data, String fallbackName) async {
    final pts = data.points;
    final geometry = [
      for (final p in pts) [p.lat, p.lon],
    ];
    final distanceM = polylineLengthMeters(geometry);

    // Prefer DEM elevation; fall back to GPX ele where the DEM is unavailable.
    final dem = await elevation.elevationsAlong(geometry);
    final elevs = <double>[
      for (var i = 0; i < pts.length; i++)
        (dem.length == pts.length && dem[i] != 0)
            ? dem[i]
            : (pts[i].ele ?? (i < dem.length ? dem[i] : 0)),
    ];
    final gl = gainLoss(elevs);

    final times = pts.map((p) => p.time).whereType<DateTime>().toList();
    final startedAt = times.isNotEmpty ? times.first : DateTime.now();
    final endedAt = times.isNotEmpty ? times.last : null;
    final totalSeconds =
        endedAt != null ? endedAt.difference(startedAt).inSeconds : 0;

    final id = _uuid.v4();
    final trackPoints = <TrackPointData>[
      for (var i = 0; i < pts.length; i++)
        TrackPointData(
          seq: i,
          t: pts[i].time ?? startedAt.add(Duration(seconds: i)),
          lat: pts[i].lat,
          lon: pts[i].lon,
          gpsAltM: pts[i].ele,
          demAltM: (dem.length == pts.length && dem[i] != 0) ? dem[i] : null,
        ),
    ];

    await tracks.saveTrack(
      TrackSummary(
        id: id,
        name: data.name ?? fallbackName,
        startedAt: startedAt,
        endedAt: endedAt,
        distanceM: distanceM,
        movingSeconds: totalSeconds,
        totalSeconds: totalSeconds,
        gainM: gl.gain,
        lossM: gl.loss,
      ),
      trackPoints,
    );
  }
}
