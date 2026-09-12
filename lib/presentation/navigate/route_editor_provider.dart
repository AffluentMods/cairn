// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/usecases/compute_route_stats.dart';
import '../../domain/usecases/edit_history.dart';
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
    this.canUndo = false,
    this.canRedo = false,
  });

  final List<EditorWaypoint> waypoints;
  final List<List<double>> polyline; // snapped route [[lat,lon],...]
  final RouteStats stats;
  final bool hasOffTrailLeg;
  final bool computing;
  final bool canUndo;
  final bool canRedo;

  bool get canSave => waypoints.length >= 2 && polyline.length >= 2;

  RouteEditorState copyWith({
    List<EditorWaypoint>? waypoints,
    List<List<double>>? polyline,
    RouteStats? stats,
    bool? hasOffTrailLeg,
    bool? computing,
    bool? canUndo,
    bool? canRedo,
  }) {
    return RouteEditorState(
      waypoints: waypoints ?? this.waypoints,
      polyline: polyline ?? this.polyline,
      stats: stats ?? this.stats,
      hasOffTrailLeg: hasOffTrailLeg ?? this.hasOffTrailLeg,
      computing: computing ?? this.computing,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class RouteEditorNotifier extends Notifier<RouteEditorState> {
  final _history = EditHistory<List<EditorWaypoint>>();

  @override
  RouteEditorState build() => const RouteEditorState();

  /// Records the current waypoints as an undo step, then applies [next].
  Future<void> _edit(List<EditorWaypoint> next) async {
    _history.push(List.of(state.waypoints));
    state = state.copyWith(waypoints: next, canUndo: true, canRedo: false);
    await recompute();
  }

  Future<void> addWaypoint(double lat, double lon) => _edit([
        ...state.waypoints,
        EditorWaypoint(lat: lat, lon: lon, onTrail: true),
      ]);

  /// Inserts a waypoint at [index] (0 to length), for a tap on a route leg
  /// (spec Phase 3); see `insertIndexForTap`.
  Future<void> insertWaypoint(int index, double lat, double lon) {
    final i = index.clamp(0, state.waypoints.length);
    return _edit(
      List.of(state.waypoints)
        ..insert(i, EditorWaypoint(lat: lat, lon: lon, onTrail: true)),
    );
  }

  /// Moves the waypoint at [index] to a new position (long-press drag).
  Future<void> moveWaypoint(int index, double lat, double lon) {
    if (index < 0 || index >= state.waypoints.length) return Future.value();
    final next = List.of(state.waypoints);
    next[index] = EditorWaypoint(lat: lat, lon: lon, onTrail: true);
    return _edit(next);
  }

  Future<void> removeAt(int index) {
    if (index < 0 || index >= state.waypoints.length) return Future.value();
    return _edit(List.of(state.waypoints)..removeAt(index));
  }

  Future<void> undo() async {
    final restored = _history.undo(List.of(state.waypoints));
    if (restored == null) return;
    state = state.copyWith(
      waypoints: restored,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
    await recompute();
  }

  Future<void> redo() async {
    final restored = _history.redo(List.of(state.waypoints));
    if (restored == null) return;
    state = state.copyWith(
      waypoints: restored,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
    await recompute();
  }

  void clear() {
    _history.clear();
    state = const RouteEditorState();
  }

  /// Load a trail (or imported line) as the active route: endpoint waypoints and
  /// the geometry as the polyline, with stats (Addendum A4.1, "Navigate this
  /// trail"). Editing (tap to add) still works from here.
  Future<void> loadPolyline(List<List<double>> geometry) async {
    _history.clear();
    if (geometry.length < 2) {
      state = const RouteEditorState();
      return;
    }
    // Set the polyline immediately so the route draws and the camera can frame
    // it right away; the stats fill in after (Fix Pass 1 X2.1).
    state = RouteEditorState(
      waypoints: [
        EditorWaypoint(
            lat: geometry.first[0], lon: geometry.first[1], onTrail: true),
        EditorWaypoint(
            lat: geometry.last[0], lon: geometry.last[1], onTrail: true),
      ],
      polyline: geometry,
      computing: true,
    );
    final stats = await computeRouteStats(
      geometry,
      ref.read(elevationRepositoryProvider),
    );
    state = state.copyWith(stats: stats, computing: false);
  }

  /// Loads a saved route with its shaping waypoints, so Customize picks up
  /// where the route was left. A route with too many stored points (an
  /// imported GPX keeps every vertex) falls back to endpoints only, since a
  /// marker per vertex is unusable.
  Future<void> loadSavedRoute(
    List<List<double>> geometry,
    List<List<double>> waypoints,
  ) async {
    if (waypoints.length < 2 || waypoints.length > 20) {
      return loadPolyline(geometry);
    }
    _history.clear();
    state = RouteEditorState(
      waypoints: [
        for (final w in waypoints)
          EditorWaypoint(lat: w[0], lon: w[1], onTrail: true),
      ],
      polyline: geometry,
      computing: true,
    );
    final stats = await computeRouteStats(
      geometry,
      ref.read(elevationRepositoryProvider),
    );
    state = state.copyWith(stats: stats, computing: false);
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

    // Snap every waypoint and route each leg in one worker isolate (Fix Pass 1
    // X1.3.1), so the ways list crosses the isolate boundary once.
    final built = await buildRouteAsync(
      ways,
      [
        for (final w in wps) [w.lat, w.lon]
      ],
    );

    final stats = await computeRouteStats(
      built.polyline,
      ref.read(elevationRepositoryProvider),
    );

    state = state.copyWith(
      waypoints: [
        for (var i = 0; i < wps.length; i++)
          EditorWaypoint(
            lat: wps[i].lat,
            lon: wps[i].lon,
            onTrail: i < built.onTrail.length ? built.onTrail[i] : true,
          ),
      ],
      polyline: built.polyline,
      stats: stats,
      hasOffTrailLeg: built.offTrail,
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
