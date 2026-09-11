// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo/resample.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../domain/models/route_plan.dart';
import '../map/map_geojson.dart';
import '../map/map_providers.dart';
import '../map/map_style.dart';
import '../map/widgets/conditions_panel.dart';
import 'route_editor_provider.dart';
import 'widgets/elevation_profile.dart';
import 'widgets/route_stats_bar.dart';
import 'widgets/waypoint_list.dart';

/// The Plan tab: tap the map to add waypoints, each snapped to the nearest
/// trail; legs follow the trail graph; a stats bar and elevation profile update
/// live (spec Phase 3).
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  MapLibreMapController? _controller;
  Circle? _scrubMarker;

  void _onMapCreated(MapLibreMapController c) => _controller = c;

  Future<void> _sync() async {
    final c = _controller;
    if (c == null) return;
    final state = ref.read(routeEditorProvider);
    await c.setGeoJsonSource(
      'cairn-route',
      lineToGeoJson(state.polyline, offTrail: state.hasOffTrailLeg),
    );
    await c.clearSymbols();
    for (var i = 0; i < state.waypoints.length; i++) {
      final w = state.waypoints[i];
      await c.addSymbol(
        SymbolOptions(
          geometry: LatLng(w.lat, w.lon),
          textField: '${i + 1}',
          textColor: '#0E1412',
          textHaloColor: '#F6F3EC',
          textHaloWidth: 1.6,
          textSize: 14,
        ),
      );
    }
  }

  Future<void> _updateScrub(double? distanceM) async {
    final c = _controller;
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

  void _openConditions() {
    final state = ref.read(routeEditorProvider);
    final poly = state.polyline;
    if (poly.length < 2) return;

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
      name: context.l10n.planTitle,
      routePolyline: poly,
      trailheadLat: poly.first[0],
      trailheadLon: poly.first[1],
      trailheadElevM: startElev,
      highLat: highPt[0],
      highLon: highPt[1],
      highElevM: highElev < -1e8 ? startElev : highElev,
      bbox: [minLat, minLon, maxLat, maxLon],
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final prefs = ref.read(sharedPreferencesProvider);
    final canSave = ref.watch(routeEditorProvider.select((s) => s.canSave));

    ref.listen(routeEditorProvider, (_, __) => _sync());
    ref.listen(scrubDistanceProvider, (_, next) => _updateScrub(next));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: l10n.planUndo,
            onPressed: () => ref.read(routeEditorProvider.notifier).undo(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.planClear,
            onPressed: () {
              ref.read(routeEditorProvider.notifier).clear();
              _sync();
            },
          ),
          IconButton(
            icon: const Icon(Icons.wb_cloudy_outlined),
            tooltip: l10n.layerConditions,
            onPressed: canSave ? _openConditions : null,
          ),
          TextButton(
            onPressed: canSave ? _save : null,
            child: Text(l10n.planSave),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MapLibreMap(
              styleString: style.assetPath,
              initialCameraPosition: initialCamera(prefs),
              compassEnabled: true,
              trackCameraPosition: true,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _sync,
              onMapClick: (point, latLng) => ref
                  .read(routeEditorProvider.notifier)
                  .addWaypoint(latLng.latitude, latLng.longitude),
              attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            ),
          ),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              height: 300,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RouteStatsBar(),
                    const SizedBox(height: 8),
                    ElevationProfile(
                      profile: ref.watch(
                        routeEditorProvider.select((s) => s.stats.profile),
                      ),
                      onScrub: (d) =>
                          ref.read(scrubDistanceProvider.notifier).state = d,
                    ),
                    const Divider(),
                    const WaypointList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
