// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo/resample.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../domain/models/route_plan.dart';
import '../map_common/cairn_map.dart';
import '../map_common/map_geojson.dart';
import '../map_common/map_providers.dart';
import '../map_common/widgets/elevation_profile.dart';
import '../shell/shell_providers.dart';
import 'recording_provider.dart';
import 'route_editor_provider.dart';
import 'widgets/live_stats_grid.dart';
import 'widgets/route_stats_bar.dart';
import 'widgets/waypoint_list.dart';

/// The Navigate tab (Addendum A4.2): the active route on a full map. Customize
/// route (tap to add snapped waypoints), see stats and the elevation profile,
/// and Start a recording that follows it. This slice merges the former Plan and
/// Record tabs; the polished draggable stats sheet, edit toolbar, and
/// Download/Start swap land in later Phase R slices.
class NavigateScreen extends ConsumerStatefulWidget {
  const NavigateScreen({super.key});

  @override
  ConsumerState<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends ConsumerState<NavigateScreen> {
  Circle? _scrubMarker;

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

  @override
  Widget build(BuildContext context) {
    final locationEnabled = ref.watch(locationEnabledProvider);
    final recording =
        ref.watch(recordingProvider.select((s) => s.status)) !=
            RecordingStatus.idle;
    final canSave = ref.watch(routeEditorProvider.select((s) => s.canSave));

    ref.listen(routeEditorProvider, (_, __) => _syncRoute());
    ref.listen(scrubDistanceProvider, (_, next) => _updateScrub(next));

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CairnMap(
                  tabIndex: ShellTab.navigate,
                  myLocationEnabled: locationEnabled || recording,
                  onStyleLoaded: (_) => _syncRoute(),
                  onMapClick: recording
                      ? null
                      : (point, latLng) => ref
                          .read(routeEditorProvider.notifier)
                          .addWaypoint(latLng.latitude, latLng.longitude),
                ),
                if (!recording)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: Column(
                      children: [
                        _RoundButton(
                          icon: Icons.undo,
                          tooltip: context.l10n.planUndo,
                          onPressed: () =>
                              ref.read(routeEditorProvider.notifier).undo(),
                        ),
                        const SizedBox(height: 8),
                        _RoundButton(
                          icon: Icons.clear_all,
                          tooltip: context.l10n.navClear,
                          onPressed: () {
                            ref.read(routeEditorProvider.notifier).clear();
                            _syncRoute();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (recording)
            _RecordingPanel(onFinish: _finish, onDiscard: _discard)
          else
            _PlanPanel(canSave: canSave, onSave: _save, onStart: _startFlow),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed),
    );
  }
}

class _PlanPanel extends ConsumerWidget {
  const _PlanPanel({
    required this.canSave,
    required this.onSave,
    required this.onStart,
  });

  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 320,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canSave ? onSave : null,
                      icon: const Icon(Icons.bookmark_border),
                      label: Text(l10n.planSave),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.navigation),
                      label: Text(l10n.navStart),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const WaypointList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingPanel extends ConsumerWidget {
  const _RecordingPanel({required this.onFinish, required this.onDiscard});

  final VoidCallback onFinish;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(recordingProvider);
    final controller = ref.read(recordingProvider.notifier);
    final paused = state.status == RecordingStatus.paused;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
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
            TextButton(
              onPressed: onDiscard,
              child: Text(l10n.recordDiscard),
            ),
          ],
        ),
      ),
    );
  }
}
