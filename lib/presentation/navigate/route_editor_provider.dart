// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/usecases/compute_route_stats.dart';
import '../../domain/usecases/route_between_waypoints.dart';
import '../../domain/usecases/snap_to_trail.dart';

/// A tapped waypoint and whether it snapped to a trail.
class EditorWaypoint {
  const EditorWaypoint({
    required this.lat,
    required this.lon,
    required this.onTrail,
  });
  final double lat;
  final double lon;
  final bool onTrail;
}

class RouteEditorState {
  const RouteEditorState({
    this.waypoints = const [],
    this.polyline = const [],
    this.stats = RouteStats.empty,
    this.hasOffTrailLeg = false,
    this.computing = false,
  });

  final List<EditorWaypoint> waypoints;
  final List<List<double>> polyline; // snapped route [[lat,lon],...]
  final RouteStats stats;
  final bool hasOffTrailLeg;
  final bool computing;

  bool get canSave => waypoints.length >= 2 && polyline.length >= 2;

  RouteEditorState copyWith({
    List<EditorWaypoint>? waypoints,
    List<List<double>>? polyline,
    RouteStats? stats,
    bool? hasOffTrailLeg,
    bool? computing,
  }) {
    return RouteEditorState(
      waypoints: waypoints ?? this.waypoints,
      polyline: polyline ?? this.polyline,
      stats: stats ?? this.stats,
      hasOffTrailLeg: hasOffTrailLeg ?? this.hasOffTrailLeg,
      computing: computing ?? this.computing,
    );
  }
}

class RouteEditorNotifier extends Notifier<RouteEditorState> {
  final _undo = <List<EditorWaypoint>>[];

  @override
  RouteEditorState build() => const RouteEditorState();

  void _pushUndo() {
    _undo.add(List.of(state.waypoints));
    if (_undo.length > 20) _undo.removeAt(0);
  }

  Future<void> addWaypoint(double lat, double lon) async {
    _pushUndo();
    state = state.copyWith(
      waypoints: [
        ...state.waypoints,
        EditorWaypoint(lat: lat, lon: lon, onTrail: true),
      ],
    );
    await recompute();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.waypoints.length) return;
    _pushUndo();
    final next = List.of(state.waypoints)..removeAt(index);
    state = state.copyWith(waypoints: next);
    await recompute();
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    state = state.copyWith(waypoints: _undo.removeLast());
    await recompute();
  }

  void clear() {
    _undo.clear();
    state = const RouteEditorState();
  }

  Future<void> recompute() async {
    final wps = state.waypoints;
    if (wps.length < 2) {
      state = state.copyWith(
        polyline: const [],
        stats: RouteStats.empty,
        hasOffTrailLeg: false,
      );
      return;
    }
    state = state.copyWith(computing: true);

    // Expand the waypoint bbox by roughly 2 km for the routing graph.
    var minLat = wps.first.lat, maxLat = wps.first.lat;
    var minLon = wps.first.lon, maxLon = wps.first.lon;
    for (final w in wps) {
      minLat = w.lat < minLat ? w.lat : minLat;
      maxLat = w.lat > maxLat ? w.lat : maxLat;
      minLon = w.lon < minLon ? w.lon : minLon;
      maxLon = w.lon > maxLon ? w.lon : maxLon;
    }
    const pad = 0.02;
    final bbox = [minLat - pad, minLon - pad, maxLat + pad, maxLon + pad];

    final trailRepo = ref.read(trailRepositoryProvider);
    await trailRepo.ensureArea(bbox);
    final ways = await trailRepo.routableWaysInBbox(bbox);

    final snapped = <SnapResult>[
      for (final w in wps) snapToTrail(w.lat, w.lon, ways),
    ];

    final polyline = <List<double>>[];
    var offTrail = false;
    for (var i = 0; i < snapped.length - 1; i++) {
      final leg = routeBetweenWaypoints(
        ways,
        snapped[i].point,
        snapped[i + 1].point,
      );
      if (leg.offTrail) offTrail = true;
      final pts = leg.polyline;
      if (i == 0) {
        polyline.addAll(pts);
      } else if (pts.isNotEmpty) {
        polyline.addAll(pts.skip(1)); // avoid duplicating the shared vertex
      }
    }

    final stats = await computeRouteStats(
      polyline,
      ref.read(elevationRepositoryProvider),
    );

    state = state.copyWith(
      waypoints: [
        for (var i = 0; i < wps.length; i++)
          EditorWaypoint(
            lat: wps[i].lat,
            lon: wps[i].lon,
            onTrail: snapped[i].onTrail,
          ),
      ],
      polyline: polyline,
      stats: stats,
      hasOffTrailLeg: offTrail,
      computing: false,
    );
  }
}

final routeEditorProvider =
    NotifierProvider<RouteEditorNotifier, RouteEditorState>(
  RouteEditorNotifier.new,
);

/// The distance along the route currently under the elevation-profile scrubber,
/// or null. The plan map places a marker here.
final scrubDistanceProvider = StateProvider<double?>((ref) => null);
