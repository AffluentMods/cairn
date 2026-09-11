// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

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
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../data/gpx/gpx_codec.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/cairn_map.dart';
import '../map_common/map_geojson.dart';
import '../map_common/map_providers.dart';
import '../map_common/widgets/elevation_profile.dart';
import '../map_common/widgets/layer_sheet.dart';
import '../map_common/widgets/location_fab.dart';
import '../map_common/widgets/stat_row.dart';
import '../saved/library_providers.dart';
import '../shell/shell_providers.dart';
import 'directions_launcher.dart';
import 'navigate_providers.dart';
import 'recording_provider.dart';
import 'route_editor_provider.dart';
import 'widgets/conditions_panel.dart';
import 'widgets/edit_toolbar.dart';
import 'widgets/live_stats_grid.dart';
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

  MapLibreMapController? get _c => ref.read(mapControllerProvider);

  Future<void> _syncRoute() async {
    final c = _c;
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

  void _enterEdit() => ref.read(editModeProvider.notifier).state = true;

  Future<void> _doneEdit() async {
    ref.read(editModeProvider.notifier).state = false;
    if (ref.read(routeEditorProvider).canSave) await _save();
  }

  void _clearRoute() {
    ref.read(routeEditorProvider.notifier).clear();
    ref.read(editModeProvider.notifier).state = false;
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
    final gpx = exportRouteGpx(
      name: 'Cairn route',
      geometry: state.polyline,
      elevations: [for (final p in state.stats.profile) p.elevM],
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
    const pad = 0.04; // roughly a 3 mile buffer around the route
    final bbox = [base[0] - pad, base[1] - pad, base[2] + pad, base[3] + pad];
    final isVector = basemap.key == 'outdoors' ||
        basemap.key == 'terrain' ||
        basemap.key == 'road';
    final est = estimateRegionBytes(
      bbox,
      minZoom: 10,
      maxZoom: 14,
      vectorStyles: isVector ? 1 : 0,
      rasterStyles: isVector ? 0 : 1,
    );
    final id = const Uuid().v4();
    final repo = ref.read(offlineRepositoryProvider);
    await repo.upsert(
      OfflineRegionModel(
        id: id,
        name: context.l10n.navRouteArea,
        minLat: bbox[0],
        minLon: bbox[1],
        maxLat: bbox[2],
        maxLon: bbox[3],
        styleKeys: [basemap.key],
        minZoom: 10,
        maxZoom: 14,
        createdAt: DateTime.now(),
        status: OfflineStatus.downloading,
        tileCount: est.tileCount,
        bytes: est.bytes,
      ),
    );
    bumpLibrary(ref);
    setState(() => _downloading = true);
    try {
      await downloadOfflineRegion(
        OfflineRegionDefinition(
          bounds: LatLngBounds(
            southwest: LatLng(bbox[0], bbox[1]),
            northeast: LatLng(bbox[2], bbox[3]),
          ),
          mapStyleUrl: basemap.assetPath,
          minZoom: 10,
          maxZoom: 14,
        ),
        metadata: {'regionId': id},
      );
      await repo.prefetchDataLayers(bbox);
      await repo.updateStatus(id, OfflineStatus.done, bytes: est.bytes);
    } catch (_) {
      await repo.updateStatus(id, OfflineStatus.error);
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
    await ref
        .read(recordingProvider.notifier)
        .start(packKg: pack.isNegative ? null : pack);
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
      name: context.l10n.tabNavigate,
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
    final recording =
        ref.watch(recordingProvider.select((s) => s.status)) !=
            RecordingStatus.idle;
    final editing = ref.watch(editModeProvider);
    final hasRoute = ref.watch(
        routeEditorProvider.select((s) => s.polyline.length >= 2));

    ref.listen(routeEditorProvider, (_, __) => _syncRoute());
    ref.listen(scrubDistanceProvider, (_, next) => _updateScrub(next));

    return Scaffold(
      body: Stack(
        children: [
          CairnMap(
            tabIndex: ShellTab.navigate,
            myLocationEnabled: locationEnabled || recording,
            onStyleLoaded: (_) => _syncRoute(),
            onMapClick: editing
                ? (point, latLng) => ref
                    .read(routeEditorProvider.notifier)
                    .addWaypoint(latLng.latitude, latLng.longitude)
                : null,
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
                    onPressed: hasRoute ? _openConditions : null,
                  ),
                  const SizedBox(height: 8),
                  _RoundButton(
                    icon: Icons.threed_rotation,
                    tooltip: context.l10n.nav3dView,
                    onPressed: () => context.push('/navigate/3d'),
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

          if (editing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditToolbar(onDone: _doneEdit),
            ),

          // Bottom content depends on the mode.
          if (recording)
            _BottomCard(
              child: _RecordingContent(onFinish: _finish, onDiscard: _discard),
            )
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
      child: IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
            l10n.planEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _RecordingContent extends ConsumerWidget {
  const _RecordingContent({required this.onFinish, required this.onDiscard});
  final VoidCallback onFinish;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(recordingProvider);
    final controller = ref.read(recordingProvider.notifier);
    final paused = state.status == RecordingStatus.paused;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveStatsGrid(),
        const SizedBox(height: 8),
        if (paused)
          Text(l10n.recordAutoPaused,
              style: Theme.of(context).textTheme.titleSmall),
        if (state.followRouteId != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.onRoute ? Icons.check_circle : Icons.error_outline,
                size: 16,
                color: state.onRoute
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(state.onRoute ? l10n.recordOnRoute : l10n.recordOffRoute),
              if (state.distanceRemainingM != null) ...[
                const SizedBox(width: 8),
                Text(l10n.recordToGo(fmt.distance(state.distanceRemainingM!))),
              ],
            ],
          ),
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
        TextButton(onPressed: onDiscard, child: Text(l10n.recordDiscard)),
      ],
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
    final profile = ref.watch(routeEditorProvider.select((s) => s.stats.profile));
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    l10n.tabNavigate,
                    style: Theme.of(context).textTheme.titleMedium,
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
            ElevationProfile(profile: profile, onScrub: onScrub),
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
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
