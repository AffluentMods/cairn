// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo/resample.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/cairn_colors.dart';
import '../../core/theme/theme_codec.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/gpx/gpx_codec.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/usecases/edit_geometry.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/cairn_map.dart';
import '../map_common/camera_provider.dart';
import '../map_common/contours_layer_sync.dart';
import '../map_common/map_geojson.dart';
import '../map_common/map_layers_provider.dart';
import '../map_common/map_providers.dart';
import '../map_common/poi_icons.dart';
import '../map_common/roads_layer_sync.dart';
import '../map_common/trails_layer_sync.dart';
import '../map_common/widgets/elevation_profile.dart';
import '../map_common/widgets/layer_sheet.dart';
import '../map_common/widgets/location_fab.dart';
import '../map_common/widgets/stat_row.dart';
import '../saved/library_providers.dart';
import '../saved/offline_download.dart';
import '../shell/shell_providers.dart';
import 'directions_launcher.dart';
import 'navigate_providers.dart';
import 'recording_provider.dart';
import 'route_editor_provider.dart';
import 'user_waypoints_layer.dart';
import 'widgets/conditions_panel.dart';
import 'widgets/edit_toolbar.dart';
import 'widgets/live_stats_grid.dart';
import 'widgets/waypoint_editor_sheet.dart';
import 'widgets/waypoint_list.dart';

/// The Navigate tab (Addendum A4.2 to A4.5): the active route on a full-screen
/// map, round map controls, a draggable stats sheet with the elevation profile
/// and the Download/Start pair, an edit mode for customizing the route, and the
/// live recording view.
class NavigateScreen extends ConsumerStatefulWidget {
  const NavigateScreen({super.key});

  @override
  ConsumerState<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends ConsumerState<NavigateScreen> {
  Circle? _scrubMarker;
  bool _downloading = false;
  bool _pendingFit = false;

  /// Whether the camera is following the location puck during recording (Fix
  /// Pass 1 X2.6). A pan dismisses it and raises the Recenter pill.
  bool _follow = true;

  MapLibreMapController? get _c => ref.read(mapControllerProvider);

  /// The shared controller belongs to whichever tab's map is live; only act on
  /// it while this tab is the active one. While another tab is showing, work
  /// stays pending and the Navigate map's next style load runs it.
  bool get _isActiveTab => ref.read(shellIndexProvider) == ShellTab.navigate;

  @override
  void initState() {
    super.initState();
    // A route loaded before this tab was first built (Navigate this trail from
    // Explore) still needs framing on the first style load.
    _pendingFit = ref.read(routeEditorProvider).polyline.length >= 2;
  }

  Future<void> _tryFit() async {
    final c = _c;
    if (c == null || !mounted || !_isActiveTab) return;
    final bbox = routeBboxOf(ref.read(routeEditorProvider).polyline);
    if (bbox == null) return;
    final media = MediaQuery.of(context);
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(bbox[0], bbox[1]),
            northeast: LatLng(bbox[2], bbox[3]),
          ),
          left: 50,
          right: 50,
          top: media.padding.top + 60,
          bottom: media.size.height * 0.44,
        ),
        duration: const Duration(milliseconds: 600),
      );
      _pendingFit = false;
    } catch (_) {
      // The shared controller was a map that just got disposed on the tab
      // switch: keep the fit pending so the new map's style load runs it.
    }
  }

  /// Drag handle (circle annotation) id to waypoint index, for drag events.
  final _handleIndex = <String, int>{};
  final _handles = <Circle>[];

  /// Waypoint marker images registered on the current style.
  final _markerIcons = <String>{};

  /// The controller whose drag events are already hooked.
  MapLibreMapController? _dragHooked;

  /// The numbered markers live in their own source and symbol layer, drawn
  /// as images (see waypointIconPng). Installed once per style.
  Future<void> _installWaypointLayer(MapLibreMapController c) async {
    _markerIcons.clear();
    try {
      await c.addSource(
        'cairn-waypoints',
        const GeojsonSourceProperties(
          data: {'type': 'FeatureCollection', 'features': <dynamic>[]},
        ),
      );
      await c.addSymbolLayer(
        'cairn-waypoints',
        'waypoint-markers',
        const SymbolLayerProperties(
          iconImage: ['get', 'icon'],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
        enableInteraction: false,
      );
    } catch (_) {
      // Already on this style.
    }
  }

  Future<void> _syncRoute() async {
    final c = _c;
    if (c == null || !_isActiveTab) return;
    final state = ref.read(routeEditorProvider);
    final editing = ref.read(editModeProvider);
    final colors = context.cairn;
    // Added images render at their pixel size over the device ratio, so a
    // 28 dp marker needs 28 physical pixels per dp of density.
    final markerPx = (28 * MediaQuery.devicePixelRatioOf(context)).round();
    // The shared controller can belong to a map that was just disposed on a
    // tab switch; the next onStyleLoaded re-syncs, so a failure here is not
    // an error worth surfacing.
    try {
      await c.setGeoJsonSource(
        'cairn-route',
        lineToGeoJson(state.polyline, offTrail: state.hasOffTrailLeg),
      );
      for (var i = 1; i <= state.waypoints.length; i++) {
        final name = 'wp-$i';
        if (_markerIcons.add(name)) {
          await c.addImage(
            name,
            await waypointIconPng(
              i,
              fill: colors.accent,
              ink: colors.onAccent,
              size: markerPx,
            ),
          );
        }
      }
      await c.setGeoJsonSource('cairn-waypoints', {
        'type': 'FeatureCollection',
        'features': [
          for (var i = 0; i < state.waypoints.length; i++)
            {
              'type': 'Feature',
              'properties': {'icon': 'wp-${i + 1}'},
              'geometry': {
                'type': 'Point',
                'coordinates': [state.waypoints[i].lon, state.waypoints[i].lat],
              },
            },
        ],
      });
      // While customizing, each marker sits on a draggable circle: a long
      // press picks it up (spec Phase 3 waypoint UX) and the drop lands in
      // moveWaypoint. The circles are annotations, drawn under the markers.
      if (_handles.isNotEmpty) await c.removeCircles(List.of(_handles));
      _handles.clear();
      _handleIndex.clear();
      if (editing) {
        for (var i = 0; i < state.waypoints.length; i++) {
          final w = state.waypoints[i];
          final handle = await c.addCircle(
            CircleOptions(
              geometry: LatLng(w.lat, w.lon),
              circleRadius: 14,
              circleColor: hexOf(colors.accent),
              circleStrokeColor: '#0E1412',
              circleStrokeWidth: 2,
              draggable: true,
            ),
          );
          _handles.add(handle);
          _handleIndex[handle.id] = i;
        }
      }
    } catch (_) {
      // disposed controller between tabs
    }
  }

  void _hookDrag(MapLibreMapController c) {
    if (identical(_dragHooked, c)) return;
    _dragHooked = c;
    c.onFeatureDrag.add(_onFeatureDrag);
  }

  void _onFeatureDrag(
    dynamic id, {
    required math.Point<double> point,
    required LatLng origin,
    required LatLng current,
    required LatLng delta,
    required DragEventType eventType,
  }) {
    if (eventType != DragEventType.end) return;
    final index = _handleIndex[id.toString()];
    if (index == null || !ref.read(editModeProvider)) return;
    unawaited(HapticFeedback.selectionClick());
    unawaited(ref
        .read(routeEditorProvider.notifier)
        .moveWaypoint(index, current.latitude, current.longitude));
  }

  /// A tap while customizing: on the route line it inserts a waypoint into
  /// that leg, anywhere else it appends one (spec Phase 3).
  Future<void> _onEditTap(math.Point<double> point, LatLng latLng) async {
    final state = ref.read(routeEditorProvider);
    final zoom = _c?.cameraPosition?.zoom ?? 14;
    final index = insertIndexForTap(
      state.polyline,
      [
        for (final w in state.waypoints) [w.lat, w.lon]
      ],
      latLng.latitude,
      latLng.longitude,
      toleranceM: 24 * metersPerPixel(latLng.latitude, zoom),
    );
    final editor = ref.read(routeEditorProvider.notifier);
    if (index != null) {
      unawaited(HapticFeedback.lightImpact());
      await editor.insertWaypoint(index, latLng.latitude, latLng.longitude);
    } else {
      await editor.addWaypoint(latLng.latitude, latLng.longitude);
    }
  }

  Future<void> _updateScrub(double? distanceM) async {
    final c = _c;
    if (c == null) return;
    final polyline = ref.read(routeEditorProvider).polyline;
    if (distanceM == null || polyline.length < 2) {
      if (_scrubMarker != null) {
        await c.removeCircle(_scrubMarker!);
        _scrubMarker = null;
      }
      return;
    }
    final pt = pointAtDistance(polyline, distanceM);
    if (pt == null) return;
    final options = CircleOptions(
      geometry: LatLng(pt[0], pt[1]),
      circleRadius: 7,
      circleColor: '#D9A441',
      circleStrokeColor: '#0E1412',
      circleStrokeWidth: 2,
    );
    if (_scrubMarker == null) {
      _scrubMarker = await c.addCircle(options);
    } else {
      await c.updateCircle(_scrubMarker!, options);
    }
  }

  // Cached OSM trails under the route (spec Phase 3: "all Phase 3 behavior
  // applies" in customize mode, and a tap snaps to trails you can see). Same
  // helper as Explore; fetching is capped the same way.
  int? _trailsSig;
  String? _contoursSig;
  int? _roadsSig;
  int _trailsGen = 0;
  bool _trailsRefreshing = false;
  bool _trailsPending = false;
  Timer? _trailsDebounce;

  @override
  void dispose() {
    _trailsDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onCameraIdleNav(MapLibreMapController c) async {
    _trailsGen++;
    _trailsDebounce?.cancel();
    _trailsDebounce = Timer(const Duration(milliseconds: 400), _refreshTrails);
  }

  Future<void> _refreshTrails() async {
    if (_trailsRefreshing) {
      _trailsPending = true;
      return;
    }
    final c = _c;
    final viewport = ref.read(viewportProvider);
    if (c == null || viewport == null || !_isActiveTab) return;
    _trailsRefreshing = true;
    final gen = _trailsGen;
    bool stale() => gen != _trailsGen;
    try {
      if (ref.read(mapLayersProvider).contains(MapOverlay.trails)) {
        final synced = await syncTrailsLayer(
          controller: c,
          viewport: viewport,
          repo: ref.read(trailRepositoryProvider),
          previousSig: _trailsSig,
          isStale: stale,
          fetch: viewportFetchesCells(viewport),
        );
        if (synced == null) return;
        _trailsSig = synced.sig;
      } else if (_trailsSig != null) {
        await c.setGeoJsonSource('cairn-trails', emptyFeatureCollection());
        _trailsSig = null;
      }
      final contoursSig = await ref.read(contourLayerSyncProvider).sync(
            controller: c,
            viewport: viewport,
            spec: contourSpecForView(
              viewport: viewport,
              enabled: ref.read(contoursEnabledProvider),
              basemapKey: ref.read(basemapProvider).key,
              units: ref.read(unitFormatterProvider).units,
            ),
            previousSig: _contoursSig,
            isStale: stale,
          );
      if (contoursSig != null) _contoursSig = contoursSig;
      if (ref.read(mapLayersProvider).contains(MapOverlay.roads)) {
        final roadsSig = await syncRoadsLayer(
          controller: c,
          viewport: viewport,
          repo: ref.read(roadRepositoryProvider),
          previousSig: _roadsSig,
          isStale: stale,
        );
        if (roadsSig != null) _roadsSig = roadsSig;
      } else if (_roadsSig != null) {
        await c.setGeoJsonSource('cairn-roads', emptyFeatureCollection());
        _roadsSig = null;
      }
    } catch (_) {
      // disposed controller between tabs
    } finally {
      _trailsRefreshing = false;
      if (_trailsPending || gen != _trailsGen) {
        _trailsPending = false;
        unawaited(_refreshTrails());
      }
    }
  }

  Future<void> _onStyleLoaded(MapLibreMapController c) async {
    _hookDrag(c);
    _handles.clear();
    _handleIndex.clear();
    _trailsSig = null;
    _contoursSig = null;
    _roadsSig = null;
    await _installWaypointLayer(c);
    await _syncRoute();
    unawaited(_refreshTrails());
    await _syncTrack();
    await _installUserWaypoints(c);
    if (_pendingFit) await _tryFit();
  }

  /// Debug builds with the route simulator on: the native puck still shows
  /// the device, so draw a marker at the simulated fix and move the camera
  /// there while following (Fix Pass 1 X2.8).
  Circle? _simPuck;

  Future<void> _syncSimPuck() async {
    final c = _c;
    if (c == null || !_isActiveTab) return;
    final rec = ref.read(recordingProvider);
    final lat = rec.currentLat;
    final lon = rec.currentLon;
    try {
      if (!rec.isActive || !rec.simulated || lat == null || lon == null) {
        if (_simPuck != null) {
          await c.removeCircle(_simPuck!);
          _simPuck = null;
        }
        return;
      }
      final options = CircleOptions(
        geometry: LatLng(lat, lon),
        circleRadius: 9,
        circleColor: '#2E90FA',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      );
      if (_simPuck == null) {
        _simPuck = await c.addCircle(options);
      } else {
        await c.updateCircle(_simPuck!, options);
      }
      if (_follow) await c.moveCamera(CameraUpdate.newLatLng(LatLng(lat, lon)));
    } catch (_) {
      // disposed controller between tabs
    }
  }

  /// The traveled path while recording (the style's teal `track` layer above
  /// the route), cleared when idle.
  Future<void> _syncTrack() async {
    final c = _c;
    if (c == null || !_isActiveTab) return;
    final rec = ref.read(recordingProvider);
    final points = rec.isActive ? rec.trackPoints : const <List<double>>[];
    try {
      await c.setGeoJsonSource(
        'cairn-track',
        points.length >= 2 ? lineToGeoJson(points) : emptyFeatureCollection(),
      );
    } catch (_) {
      // disposed controller between tabs
    }
  }

  Future<void> _installUserWaypoints(MapLibreMapController c) async {
    final wps =
        ref.read(userWaypointsProvider).valueOrNull ?? const <UserWaypoint>[];
    try {
      await c.addSource(
        'cairn-user-waypoints',
        GeojsonSourceProperties(data: userWaypointsGeoJson(wps)),
      );
      await c.addCircleLayer(
        'cairn-user-waypoints',
        'user-waypoints-layer',
        const CircleLayerProperties(
          circleColor: ['get', 'color'],
          circleRadius: 7.0,
          circleStrokeColor: '#0E1412',
          circleStrokeWidth: 2.0,
        ),
      );
    } catch (_) {
      // Already installed on this style; just refresh the data.
      await _refreshUserWaypoints();
    }
  }

  Future<void> _refreshUserWaypoints() async {
    final c = _c;
    if (c == null) return;
    final wps =
        ref.read(userWaypointsProvider).valueOrNull ?? const <UserWaypoint>[];
    try {
      await c.setGeoJsonSource(
          'cairn-user-waypoints', userWaypointsGeoJson(wps));
    } catch (_) {}
  }

  Future<void> _onLongPress(math.Point<double> point, LatLng latLng) =>
      showWaypointEditor(context, lat: latLng.latitude, lon: latLng.longitude);

  Future<void> _onMapClickNav(math.Point<double> point, LatLng latLng) async {
    final c = _c;
    if (c == null) return;
    if (ref.read(dropWaypointModeProvider)) {
      ref.read(dropWaypointModeProvider.notifier).state = false;
      unawaited(HapticFeedback.lightImpact()); // the pin landed (Section 9.7)
      await showWaypointEditor(context,
          lat: latLng.latitude, lon: latLng.longitude);
      return;
    }
    try {
      final features =
          await c.queryRenderedFeatures(point, ['user-waypoints-layer'], null);
      if (features.isEmpty) return;
      final props = (features.first as Map)['properties'];
      final id = props is Map ? props['id'] as String? : null;
      if (id == null) return;
      final wps =
          ref.read(userWaypointsProvider).valueOrNull ?? const <UserWaypoint>[];
      UserWaypoint? wp;
      for (final w in wps) {
        if (w.id == id) {
          wp = w;
          break;
        }
      }
      if (wp != null && mounted) {
        await showWaypointEditor(context,
            lat: wp.lat, lon: wp.lon, existing: wp);
      }
    } catch (_) {}
  }

  void _enterEdit() => ref.read(editModeProvider.notifier).state = true;

  Future<void> _doneEdit() async {
    ref.read(editModeProvider.notifier).state = false;
    if (ref.read(routeEditorProvider).canSave) await _save();
  }

  void _clearRoute() {
    ref.read(routeEditorProvider.notifier).clear();
    ref.read(editModeProvider.notifier).state = false;
    ref.read(activeRouteNameProvider.notifier).state = null;
    ref.read(routeStartDistanceProvider.notifier).state = null;
    _syncRoute();
  }

  Future<void> _save() async {
    final state = ref.read(routeEditorProvider);
    if (!state.canSave) return;
    final name = await _promptName();
    if (name == null || name.trim().isEmpty) return;
    final now = DateTime.now();
    final stats = state.stats;
    final route = SavedRoute(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      geometry: state.polyline,
      distanceM: stats.distanceM,
      gainM: stats.gainM,
      lossM: stats.lossM,
      maxElevM: stats.maxElevM,
      minElevM: stats.minElevM,
      waypoints: [
        for (final w in state.waypoints)
          RouteWaypointModel(lat: w.lat, lon: w.lon),
      ],
    );
    await ref.read(routeRepositoryProvider).save(route);
    bumpLibrary(ref);
    if (!mounted) return;
    final fmt = ref.read(unitFormatterProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.recordSavedSummary(
            fmt.distance(stats.distanceM),
            fmt.elevationSigned(stats.gainM),
          ),
        ),
      ),
    );
  }

  Future<String?> _promptName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.planNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.planSave),
          ),
        ],
      ),
    );
  }

  Future<void> _exportGpx() async {
    final state = ref.read(routeEditorProvider);
    if (state.polyline.length < 2) return;
    final pins =
        ref.read(userWaypointsProvider).valueOrNull ?? const <UserWaypoint>[];
    final gpx = exportRouteGpx(
      name: ref.read(activeRouteNameProvider) ?? context.l10n.routeUnnamed,
      geometry: state.polyline,
      elevations: [for (final p in state.stats.profile) p.elevM],
      waypoints: [
        for (final w in pins)
          GpxWaypoint(
              lat: w.lat, lon: w.lon, name: w.name, note: w.note, kind: w.kind),
      ],
    );
    final bytes = Uint8List.fromList(utf8.encode(gpx));
    await Share.shareXFiles([
      XFile.fromData(bytes, name: 'route.gpx', mimeType: 'application/gpx+xml'),
    ]);
  }

  Future<void> _downloadRoute() async {
    final poly = ref.read(routeEditorProvider).polyline;
    final base = routeBboxOf(poly);
    if (base == null) return;
    final basemap = ref.read(basemapProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (!basemap.offlineAllowed) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.navDownloadNotOffline)),
      );
      return;
    }
    // A route bundle: the area around the route at z10 to z14 plus trail
    // detail (z15 to z16) in a 1.5 km corridor along it, then trails, POIs,
    // land, and terrain (docs/DECISIONS.md, route-corridor downloads).
    const pad = 0.04; // roughly a 3 mile buffer around the route
    final bbox = [base[0] - pad, base[1] - pad, base[2] + pad, base[3] + pad];
    final corridor = corridorBoxes(poly);
    final id = const Uuid().v4();
    final name = ref.read(activeRouteNameProvider) ?? context.l10n.navRouteArea;
    var region = OfflineRegionModel(
      id: id,
      name: name,
      minLat: bbox[0],
      minLon: bbox[1],
      maxLat: bbox[2],
      maxLon: bbox[3],
      styleKeys: [basemap.key],
      minZoom: 10,
      maxZoom: 14,
      createdAt: DateTime.now(),
      status: OfflineStatus.downloading,
    );
    final est = estimateRegion(region, corridor: corridor);
    region = OfflineRegionModel(
      id: id,
      name: name,
      minLat: bbox[0],
      minLon: bbox[1],
      maxLat: bbox[2],
      maxLon: bbox[3],
      styleKeys: [basemap.key],
      minZoom: 10,
      maxZoom: 14,
      createdAt: region.createdAt,
      status: OfflineStatus.downloading,
      tileCount: est.tileCount,
      bytes: est.bytes,
    );
    final repo = ref.read(offlineRepositoryProvider);
    await repo.upsert(region);
    bumpLibrary(ref);
    setState(() => _downloading = true);
    try {
      await downloadRegionBundle(repo, region, corridor: corridor);
    } finally {
      if (mounted) setState(() => _downloading = false);
      bumpLibrary(ref);
    }
  }

  Future<void> _startFlow() async {
    final defaultPack = ref.read(settingsProvider).defaultPackKg;
    final pack = await _promptPack(defaultPack);
    if (pack == null) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _follow = true); // follow from the first fix
    // Navigation zoom before follow mode takes over (it keeps the current
    // zoom): a route framed at z12 is useless for spotting the next bend.
    final c = _c;
    if (c != null && (c.cameraPosition?.zoom ?? 16) < 15) {
      try {
        await c.animateCamera(CameraUpdate.zoomTo(16));
      } catch (_) {}
    }
    if (!mounted) return;
    final labels = RecordingLabels.fromL10n(context.l10n);
    await ref.read(recordingProvider.notifier).start(
          labels: labels,
          packKg: pack.isNegative ? null : pack,
        );
    if (pack > 0) {
      await ref.read(settingsProvider.notifier).setDefaultPackKg(pack);
    }
  }

  Future<double?> _promptPack(double? initial) {
    final l10n = context.l10n;
    final metric = ref.read(settingsProvider).units == UnitSystem.metric;
    final controller = TextEditingController(
      text: initial == null
          ? ''
          : (metric ? initial : initial / 0.45359237).toStringAsFixed(0),
    );
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recordPackPrompt),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: metric ? 'kg' : 'lb'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1.0),
            child: Text(l10n.genericSkip),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text) ?? 0;
              final kg = metric ? v : v * 0.45359237;
              Navigator.pop(context, kg);
            },
            child: Text(l10n.recordStart),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    final fmt = ref.read(unitFormatterProvider);
    final messenger = ScaffoldMessenger.of(context);
    // A confirm guards against an accidental stop mid-hike; Pause stays one
    // tap (AllTrails hides Finish behind Pause for the same reason).
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.recordFinishConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recordFinish),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HapticFeedback.mediumImpact();
    final summary = await ref.read(recordingProvider.notifier).finish();
    if (summary != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.recordSavedSummary(
              fmt.distance(summary.distanceM),
              fmt.elevationSigned(summary.gainM),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _discard() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.recordDiscardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recordDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HapticFeedback.heavyImpact();
      await ref.read(recordingProvider.notifier).discard();
    }
  }

  Future<void> _openConditions() async {
    final state = ref.read(routeEditorProvider);
    final poly = state.polyline;
    if (poly.length < 2) {
      // No route loaded: conditions for the map center (spec audit gap 30),
      // so fires, weather, and alerts are one tap away while exploring.
      final cam = ref.read(cameraProvider);
      final lat = cam.target.latitude;
      final lon = cam.target.longitude;
      final elev =
          await ref.read(elevationRepositoryProvider).elevationAt(lat, lon) ??
              0.0;
      if (!mounted) return;
      showConditions(
        context,
        name: context.l10n.condHere,
        routePolyline: [
          [lat, lon]
        ],
        trailheadLat: lat,
        trailheadLon: lon,
        trailheadElevM: elev,
        highLat: lat,
        highLon: lon,
        highElevM: elev,
        bbox: [lat - 0.15, lon - 0.2, lat + 0.15, lon + 0.2],
      );
      return;
    }

    final profile = state.stats.profile;
    var highDist = 0.0;
    var highElev = -1e9;
    final startElev = profile.isEmpty ? 0.0 : profile.first.elevM;
    for (final p in profile) {
      if (p.elevM > highElev) {
        highElev = p.elevM;
        highDist = p.distanceM;
      }
    }
    final highPt = pointAtDistance(poly, highDist) ?? poly.last;

    var minLat = poly.first[0], maxLat = poly.first[0];
    var minLon = poly.first[1], maxLon = poly.first[1];
    for (final p in poly) {
      minLat = p[0] < minLat ? p[0] : minLat;
      maxLat = p[0] > maxLat ? p[0] : maxLat;
      minLon = p[1] < minLon ? p[1] : minLon;
      maxLon = p[1] > maxLon ? p[1] : maxLon;
    }

    showConditions(
      context,
      name: ref.read(activeRouteNameProvider) ?? context.l10n.routeUnnamed,
      routePolyline: poly,
      trailheadLat: poly.first[0],
      trailheadLon: poly.first[1],
      trailheadElevM: startElev,
      highLat: highPt[0],
      highLon: highPt[1],
      highElevM: highElev < -1e8 ? startElev : highElev,
      bbox: [minLat, minLon, maxLat, maxLon],
      profile: profile,
    );
  }

  Future<void> _openDirections() async {
    final waypoints = ref.read(routeEditorProvider).waypoints;
    if (waypoints.isEmpty) return;
    final first = waypoints.first;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await openDirections(first.lat, first.lon);
    if (!ok && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.navDirectionsFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final locationEnabled = ref.watch(locationEnabledProvider);
    final recording = ref.watch(recordingProvider.select((s) => s.status)) !=
        RecordingStatus.idle;
    // Off-route banner inputs, selected so the map does not rebuild on every
    // clock tick of the recording state.
    final offRoute = ref.watch(recordingProvider.select((s) => (
          show: s.isActive &&
              !s.onRoute &&
              !s.offRouteMuted &&
              s.offRouteDistanceM != null,
          distanceM: s.offRouteDistanceM ?? 0,
          bearingBack: s.bearingBackDeg,
          heading: s.heading,
        )));
    final editing = ref.watch(editModeProvider);
    final hasRoute =
        ref.watch(routeEditorProvider.select((s) => s.polyline.length >= 2));
    final startDist = ref.watch(routeStartDistanceProvider);
    final startFar = hasRoute &&
        !editing &&
        !recording &&
        startDist != null &&
        startDist > 1609;

    ref.listen(routeEditorProvider, (_, __) => _syncRoute());
    // Entering or leaving customize mode re-adds the numbers as draggable
    // or fixed.
    ref.listen(editModeProvider, (_, __) => _syncRoute());
    ref.listen(
      recordingProvider.select((s) => (s.trackVersion, s.isActive)),
      (_, __) => _syncTrack(),
    );
    ref.listen(
      recordingProvider.select((s) => (s.fixSeq, s.simulated, s.isActive)),
      (_, __) => _syncSimPuck(),
    );
    final simulated = ref.watch(recordingProvider.select((s) => s.simulated));
    ref.listen(scrubDistanceProvider, (_, next) => _updateScrub(next));
    ref.listen(userWaypointsProvider, (_, __) => _refreshUserWaypoints());
    ref.listen(fitRouteProvider, (_, __) {
      _pendingFit = true;
      _tryFit();
    });
    // Layer switches (trails, contours) and a units change redraw the view.
    ref.listen(mapLayersProvider, (_, __) {
      _trailsGen++;
      unawaited(_refreshTrails());
    });
    ref.listen(contoursEnabledProvider, (_, __) {
      _trailsGen++;
      unawaited(_refreshTrails());
    });
    ref.listen(unitFormatterProvider, (_, __) {
      _trailsGen++;
      unawaited(_refreshTrails());
    });

    return Scaffold(
      body: Stack(
        children: [
          CairnMap(
            tabIndex: ShellTab.navigate,
            myLocationEnabled: locationEnabled || recording,
            trackingMode: recording && _follow && !simulated
                ? MyLocationTrackingMode.trackingCompass
                : MyLocationTrackingMode.none,
            onCameraTrackingDismissed: recording
                ? () {
                    if (_follow) setState(() => _follow = false);
                  }
                : null,
            onStyleLoaded: _onStyleLoaded,
            onCameraIdle: _onCameraIdleNav,
            onMapClick:
                editing ? _onEditTap : (recording ? null : _onMapClickNav),
            onMapLongClick: (editing || recording) ? null : _onLongPress,
          ),

          // Map controls, hidden while editing (the toolbar takes over).
          if (!editing && !recording)
            Positioned(
              top: topInset + 8,
              right: 12,
              child: Column(
                children: [
                  const LayerSwitcherButton(),
                  const SizedBox(height: 8),
                  _RoundButton(
                    icon: Icons.wb_cloudy_outlined,
                    tooltip: context.l10n.layerConditions,
                    onPressed: _openConditions,
                  ),
                  const SizedBox(height: 8),
                  _RoundButton(
                    icon: Icons.threed_rotation,
                    tooltip: context.l10n.nav3dView,
                    onPressed: () => context.push('/navigate/3d'),
                  ),
                  const SizedBox(height: 8),
                  _RoundButton(
                    icon: Icons.add_location_alt_outlined,
                    tooltip: context.l10n.waypointAdd,
                    active: ref.watch(dropWaypointModeProvider),
                    onPressed: () => ref
                        .read(dropWaypointModeProvider.notifier)
                        .state = !ref.read(dropWaypointModeProvider),
                  ),
                ],
              ),
            ),
          if (!editing && !recording)
            Positioned(
              top: topInset + 8,
              left: 12,
              child: Column(
                children: [
                  _RoundButton(
                    icon: Icons.timeline_outlined,
                    tooltip: context.l10n.navCustomizeRoute,
                    active: false,
                    onPressed: _enterEdit,
                  ),
                  const SizedBox(height: 8),
                  _RoundButton(
                    icon: Icons.directions_outlined,
                    tooltip: context.l10n.navDirections,
                    onPressed: hasRoute ? _openDirections : null,
                  ),
                ],
              ),
            ),
          if (!editing)
            const Positioned(right: 16, bottom: 24, child: LocationFab()),

          // Off-route banner (spec Phase 6, Fix Pass 1 X2.6): how far, an
          // arrow back to the trail (relative to heading when known), and a
          // Mute that re-arms once the hiker is back on the route.
          if (offRoute.show)
            Positioned(
              top: topInset + 8,
              left: 12,
              right: 12,
              child: Material(
                color: context.cairn.raised,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: ((offRoute.bearingBack ?? 0) -
                                (offRoute.heading ?? 0)) *
                            math.pi /
                            180.0,
                        child: Icon(Icons.navigation,
                            size: 20,
                            color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.recordOffRouteBy(
                            ref
                                .watch(unitFormatterProvider)
                                .distance(offRoute.distanceM),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.cairn.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(recordingProvider.notifier).muteOffRoute(),
                        child: Text(context.l10n.recordMuteOffRoute),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Recenter pill: shown when the hiker pans away during recording, so
          // one tap resumes heading-up follow (Fix Pass 1 X2.6).
          if (recording && !_follow)
            Positioned(
              top: topInset + (offRoute.show ? 64 : 12),
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: context.cairn.accent,
                  borderRadius: BorderRadius.circular(22),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _follow = true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location,
                              size: 18, color: context.cairn.onAccent),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.navRecenter,
                            style: TextStyle(
                              color: context.cairn.onAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Trailhead-is-far banner with directions (Fix Pass 1 X2.2).
          if (startFar)
            Positioned(
              top: topInset + 8,
              left: 68,
              right: 68,
              child: Material(
                color: context.cairn.raised,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  child: Row(
                    children: [
                      Icon(Icons.pin_drop_outlined,
                          size: 18, color: context.cairn.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.navStartFar(
                            ref
                                .watch(unitFormatterProvider)
                                .distance(startDist),
                          ),
                          style: TextStyle(
                              fontSize: 13, color: context.cairn.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final poly = ref.read(routeEditorProvider).polyline;
                          if (poly.isNotEmpty) {
                            openDirections(poly.first[0], poly.first[1],
                                label: ref.read(activeRouteNameProvider));
                          }
                        },
                        child: Text(context.l10n.navDirections),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (editing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditToolbar(onDone: _doneEdit),
            ),

          // Bottom content depends on the mode.
          if (recording)
            _RecordingSheet(onFinish: _finish, onDiscard: _discard)
          else if (editing)
            const _BottomCard(child: _EditStatsBar())
          else if (hasRoute)
            _LoadedSheet(
              downloading: _downloading,
              onCustomize: _enterEdit,
              onClear: _clearRoute,
              onDownload: _downloadRoute,
              onStart: _startFlow,
              onSave: _save,
              onExport: _exportGpx,
              onScrub: (d) =>
                  ref.read(scrubDistanceProvider.notifier).state = d,
            )
          else
            _BottomCard(child: _EmptyContent(onCustomize: _enterEdit)),
        ],
      ),
    );
  }
}

/// A 52 dp round map button. Toggles get a larch outline instead of a fill.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: CircleBorder(
        side: active
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child:
          IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed),
    );
  }
}

/// A plain bottom card used for the empty, editing, and recording states.
class _BottomCard extends StatelessWidget {
  const _BottomCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.onCustomize});
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.navEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.navEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCustomize,
            icon: const Icon(Icons.timeline_outlined),
            label: Text(l10n.navCustomizeRoute),
          ),
        ),
      ],
    );
  }
}

class _EditStatsBar extends ConsumerWidget {
  const _EditStatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(unitFormatterProvider);
    final stats = ref.watch(routeEditorProvider.select((s) => s.stats));
    final has =
        ref.watch(routeEditorProvider.select((s) => s.polyline.length >= 2));
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatRow(
          distance: has ? fmt.distance(stats.distanceM) : null,
          gain: has ? fmt.elevation(stats.gainM) : null,
          loss: has ? fmt.elevation(stats.lossM) : null,
          time: has && stats.estimatedTime > Duration.zero
              ? UnitFormatter.durationHm(stats.estimatedTime)
              : null,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            has ? l10n.planEditHint : l10n.planEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

/// The live recording sheet (spec Section 9.6, Fix Pass 1 X2.6). Collapsed it
/// shows just the three headline numbers, the route status, and Pause and
/// Finish, so the map stays the hero while navigating; dragging up reveals
/// the full stats, the profile with the position dot, and Discard.
class _RecordingSheet extends ConsumerWidget {
  const _RecordingSheet({required this.onFinish, required this.onDiscard});
  final VoidCallback onFinish;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(recordingProvider);
    final controller = ref.read(recordingProvider.notifier);
    final paused = state.status == RecordingStatus.paused;
    final following = state.routeLengthM != null;
    final profile = following
        ? ref.watch(routeEditorProvider.select((s) => s.stats.profile))
        : null;
    // Notes push the peek down so the buttons stay reachable.
    final notes = (state.recovered ? 1 : 0) + (state.batteryRestricted ? 1 : 0);
    final peek = 0.30 + 0.09 * notes;

    return DraggableScrollableSheet(
      initialChildSize: peek,
      minChildSize: peek,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: [peek, 0.92],
      builder: (context, scrollController) => Material(
        color: scheme.surface,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (state.recovered)
              _RecordingNote(
                icon: Icons.restore,
                text: l10n.recordRecovered,
              ),
            if (state.batteryRestricted)
              _RecordingNote(
                icon: Icons.battery_alert_outlined,
                text: l10n.recordBatteryRestricted,
                actionLabel: l10n.recordBatteryFix,
                onAction: controller.openBatterySettings,
                onDismiss: controller.dismissBatteryHint,
              ),
            const RecordingPrimaryRow(),
            const SizedBox(height: 2),
            if (state.arrived)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_circle, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(l10n.recordArrived,
                        style: theme.textTheme.titleSmall),
                  ),
                ],
              )
            else if (paused)
              Text(
                state.autoPaused ? l10n.recordAutoPaused : l10n.recordPaused,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              )
            else if (following &&
                state.onRoute &&
                state.climbRemainingM != null &&
                state.climbGainLeftM != null)
              // The climb pill (AllTrails' elevation mode): how far and how
              // much higher to the top of the climb under way.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.recordClimbLeft(
                        ref.watch(unitFormatterProvider).distance(
                              state.climbRemainingM!,
                            ),
                        ref.watch(unitFormatterProvider).elevation(
                              state.climbGainLeftM!,
                            ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else if (following && state.routeKnown)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.onRoute ? Icons.check_circle : Icons.error_outline,
                    size: 16,
                    color: state.onRoute ? scheme.secondary : scheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                      state.onRoute ? l10n.recordOnRoute : l10n.recordOffRoute),
                ],
              )
            else if (following)
              Text(
                l10n.recordWaitingGps,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              const SizedBox(height: 20),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await HapticFeedback.mediumImpact();
                      paused ? controller.resume() : controller.pause();
                    },
                    icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                    label: Text(paused ? l10n.recordResume : l10n.recordPause),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.recordFinish),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const RecordingDetailGrid(),
            if (profile != null && profile.length >= 2) ...[
              const SizedBox(height: 8),
              ElevationProfile(
                profile: profile,
                progressDistanceM: state.progressM,
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onDiscard,
                child: Text(l10n.recordDiscard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A one-line note above the live stats (recovered session, battery hint).
class _RecordingNote extends StatelessWidget {
  const _RecordingNote({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final cairn = context.cairn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cairn.raised,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cairn.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13, color: cairn.textPrimary),
                ),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: context.l10n.navClose,
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The route-loaded stats sheet (Addendum A4.2): drag from a peek of the stats
/// up through the profile and the Download/Start pair to the waypoint list.
class _LoadedSheet extends ConsumerWidget {
  const _LoadedSheet({
    required this.downloading,
    required this.onCustomize,
    required this.onClear,
    required this.onDownload,
    required this.onStart,
    required this.onSave,
    required this.onExport,
    required this.onScrub,
  });

  final bool downloading;
  final VoidCallback onCustomize;
  final VoidCallback onClear;
  final VoidCallback onDownload;
  final VoidCallback onStart;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final ValueChanged<double?> onScrub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fmt = ref.watch(unitFormatterProvider);
    final stats = ref.watch(routeEditorProvider.select((s) => s.stats));
    final profile =
        ref.watch(routeEditorProvider.select((s) => s.stats.profile));
    final covered = ref.watch(routeCoveredProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.14,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.14, 0.42, 0.9],
      builder: (context, controller) => Material(
        color: scheme.surface,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ref.watch(activeRouteNameProvider) ?? l10n.routeUnnamed,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l10n.navClear,
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatRow(
              distance: fmt.distance(stats.distanceM),
              gain: fmt.elevation(stats.gainM),
              loss: fmt.elevation(stats.lossM),
              time: stats.estimatedTime > Duration.zero
                  ? UnitFormatter.durationHm(stats.estimatedTime)
                  : null,
            ),
            const SizedBox(height: 12),
            ElevationProfile(
              profile: profile,
              onScrub: onScrub,
              waterMarksM:
                  ref.watch(routeWaterMarksProvider).valueOrNull ?? const [],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: covered
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check),
                          label: Text(l10n.navDownloaded),
                        )
                      : FilledButton.icon(
                          onPressed: downloading ? null : onDownload,
                          icon: downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(l10n.navDownload),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: covered
                      ? FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.navigation),
                          label: Text(l10n.navStart),
                        )
                      : OutlinedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.navigation),
                          label: Text(l10n.navStart),
                        ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onCustomize,
                  icon: const Icon(Icons.timeline_outlined, size: 18),
                  label: Text(l10n.navCustomizeRoute),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: Text(l10n.planSave),
                ),
                IconButton(
                  onPressed: onExport,
                  icon: const Icon(Icons.ios_share, size: 20),
                  tooltip: l10n.gpxExport,
                ),
              ],
            ),
            const WaypointList(),
          ],
        ),
      ),
    );
  }
}
