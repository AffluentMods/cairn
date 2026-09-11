// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import 'map_geojson.dart';
import 'map_layers_provider.dart';
import 'map_providers.dart';
import 'map_style.dart';
import 'poi_icons.dart';
import 'widgets/layer_switcher_sheet.dart';
import 'widgets/location_fab.dart';
import 'widgets/trail_detail_sheet.dart';
import 'widgets/trail_search.dart';

/// The Map tab: a full-screen MapLibre map with switchable styles, hillshade,
/// the user location puck, compass, the layer switcher, and OSM trails and POIs
/// loaded per viewport and cached (spec Phases 1 and 2).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _controller;
  Timer? _debounce;
  bool _refreshing = false;
  bool _pending = false;
  bool _showOfflineBanner = false;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    ref.read(mapControllerProvider.notifier).state = controller;
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await addCairnIcons(controller);
    await ref.read(viewportProvider.notifier).updateFrom(controller);
    await _refreshOverlays();
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    if (controller == null) return;
    await ref.read(viewportProvider.notifier).updateFrom(controller);
    await persistCamera(ref.read(sharedPreferencesProvider), controller);
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _refreshOverlays);
  }

  Future<void> _refreshOverlays() async {
    if (_refreshing) {
      _pending = true;
      return;
    }
    final controller = _controller;
    final viewport = ref.read(viewportProvider);
    if (controller == null || viewport == null) return;
    _refreshing = true;
    try {
      final layers = ref.read(mapLayersProvider);

      if (layers.contains(MapOverlay.trails)) {
        final repo = ref.read(trailRepositoryProvider);
        final result = await repo.ensureArea(viewport.bbox);
        final trails = await repo.trailsInBbox(viewport.bbox);
        await controller.setGeoJsonSource(
          'cairn-trails',
          trailsToGeoJson(trails, zoom: viewport.zoom),
        );
        if (mounted && result.networkError && trails.isEmpty) {
          setState(() => _showOfflineBanner = true);
        }
      } else {
        await controller.setGeoJsonSource(
          'cairn-trails',
          emptyFeatureCollection(),
        );
      }

      if (layers.contains(MapOverlay.pois)) {
        final repo = ref.read(poiRepositoryProvider);
        await repo.ensureArea(viewport.bbox);
        final pois = await repo.poisInBbox(viewport.bbox);
        await controller.setGeoJsonSource('cairn-pois', poisToGeoJson(pois));
      } else {
        await controller.setGeoJsonSource(
          'cairn-pois',
          emptyFeatureCollection(),
        );
      }

      if (layers.contains(MapOverlay.fires)) {
        final fires = await ref
            .read(conditionsRepositoryProvider)
            .firesInBbox(viewport.bbox);
        await controller.setGeoJsonSource('cairn-fires', firesToGeoJson(fires));
      } else {
        await controller.setGeoJsonSource(
          'cairn-fires',
          emptyFeatureCollection(),
        );
      }

      if (layers.contains(MapOverlay.land)) {
        final land = await ref
            .read(conditionsRepositoryProvider)
            .landInBbox(viewport.bbox);
        await controller.setGeoJsonSource('cairn-land', landToGeoJson(land));
      } else {
        await controller.setGeoJsonSource(
          'cairn-land',
          emptyFeatureCollection(),
        );
      }
    } finally {
      _refreshing = false;
      if (_pending) {
        _pending = false;
        unawaited(_refreshOverlays());
      }
    }
  }

  Future<void> _onMapClick(math.Point<double> point, LatLng latLng) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final features =
          await controller.queryRenderedFeatures(point, ['trails'], null);
      if (features.isEmpty) return;
      final props = (features.first as Map)['properties'];
      final id = (props is Map) ? props['id'] : null;
      if (id == null) return;
      final trail = await ref.read(trailRepositoryProvider).byId(
            (id as num).toInt(),
          );
      if (trail != null && mounted) {
        await showTrailDetail(context, trail);
      }
    } catch (_) {
      // A tap that hits nothing is not an error.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final locationEnabled = ref.watch(locationEnabledProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final topInset = MediaQuery.of(context).padding.top;

    // Re-render overlays when the enabled layer set changes.
    ref.listen(mapLayersProvider, (_, __) => _refreshOverlays());

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: style.assetPath,
            initialCameraPosition: initialCamera(prefs),
            myLocationEnabled: locationEnabled,
            myLocationRenderMode: locationEnabled
                ? MyLocationRenderMode.compass
                : MyLocationRenderMode.normal,
            compassEnabled: true,
            trackCameraPosition: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraIdle: _onCameraIdle,
            onMapClick: _onMapClick,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.search),
                tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                onPressed: () => showTrailSearch(context),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 12,
            child: const LayerSwitcherButton(),
          ),
          const Positioned(right: 16, bottom: 24, child: LocationFab()),
          if (_showOfflineBanner)
            Positioned(
              top: topInset + 60,
              left: 12,
              right: 12,
              child: _OfflineBanner(
                onDismiss: () => setState(() => _showOfflineBanner = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.trailsOfflineBanner,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
