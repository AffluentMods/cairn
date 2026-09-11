// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../domain/models/trail.dart';
import '../map_common/cairn_map.dart';
import '../map_common/map_geojson.dart';
import '../map_common/map_layers_provider.dart';
import '../map_common/map_providers.dart';
import '../map_common/widgets/layer_sheet.dart';
import '../map_common/widgets/location_fab.dart';
import '../shell/shell_providers.dart';
import 'widgets/trail_detail_sheet.dart';
import 'widgets/trail_search.dart';

/// The Explore tab (Addendum A4.1): a full-screen map with switchable base maps,
/// OSM trails and POIs loaded per viewport, search, and a "Trails in view" sheet
/// listing the named trails currently on screen. Tapping a trail opens its
/// detail sheet.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  Timer? _debounce;
  bool _refreshing = false;
  bool _pending = false;
  bool _showOfflineBanner = false;
  List<Trail> _nearby = const [];

  MapLibreMapController? get _controller => ref.read(mapControllerProvider);

  Future<void> _onStyleLoaded(MapLibreMapController c) => _refreshOverlays();

  Future<void> _onCameraIdle(MapLibreMapController c) async {
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
      var trails = const <Trail>[];

      if (layers.contains(MapOverlay.trails)) {
        final repo = ref.read(trailRepositoryProvider);
        final result = await repo.ensureArea(viewport.bbox);
        trails = await repo.trailsInBbox(viewport.bbox);
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
        await controller.setGeoJsonSource('cairn-pois', emptyFeatureCollection());
      }

      if (layers.contains(MapOverlay.fires)) {
        final fires = await ref
            .read(conditionsRepositoryProvider)
            .firesInBbox(viewport.bbox);
        await controller.setGeoJsonSource('cairn-fires', firesToGeoJson(fires));
      } else {
        await controller.setGeoJsonSource('cairn-fires', emptyFeatureCollection());
      }

      if (layers.contains(MapOverlay.land)) {
        final land = await ref
            .read(conditionsRepositoryProvider)
            .landInBbox(viewport.bbox);
        await controller.setGeoJsonSource('cairn-land', landToGeoJson(land));
      } else {
        await controller.setGeoJsonSource('cairn-land', emptyFeatureCollection());
      }

      if (mounted) setState(() => _nearby = trails);
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
      final trail =
          await ref.read(trailRepositoryProvider).byId((id as num).toInt());
      if (trail != null && mounted) await showTrailDetail(context, trail);
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
    final locationEnabled = ref.watch(locationEnabledProvider);
    final topInset = MediaQuery.of(context).padding.top;

    ref.listen(mapLayersProvider, (_, __) => _refreshOverlays());

    return Scaffold(
      body: Stack(
        children: [
          CairnMap(
            tabIndex: ShellTab.explore,
            myLocationEnabled: locationEnabled,
            onStyleLoaded: _onStyleLoaded,
            onCameraIdle: _onCameraIdle,
            onMapClick: _onMapClick,
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            child: Material(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.search),
                tooltip: context.l10n.exploreSearchHint,
                onPressed: () => showTrailSearch(context),
              ),
            ),
          ),
          Positioned(top: topInset + 8, right: 12, child: const LayerSwitcherButton()),
          const Positioned(right: 16, bottom: 200, child: LocationFab()),
          if (_showOfflineBanner)
            Positioned(
              top: topInset + 60,
              left: 12,
              right: 12,
              child: _OfflineBanner(
                onDismiss: () => setState(() => _showOfflineBanner = false),
              ),
            ),
          _NearbyTrailsSheet(
            trails: _nearby,
            onTap: (t) => showTrailDetail(context, t),
          ),
        ],
      ),
    );
  }
}

class _NearbyTrailsSheet extends ConsumerWidget {
  const _NearbyTrailsSheet({required this.trails, required this.onTap});

  final List<Trail> trails;
  final void Function(Trail) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.read(unitFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final named = trails.where((t) => (t.name ?? '').isNotEmpty).take(50).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.18,
      minChildSize: 0.18,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.18, 0.5, 0.85],
      builder: (context, scroll) => Material(
        color: scheme.surface,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    l10n.exploreTrailsInView,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text('${named.length}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            if (named.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Text(
                  l10n.exploreEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            for (final t in named)
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text(t.name ?? l10n.trailUnnamed),
                subtitle: Text(
                  t.usfsNumber != null
                      ? l10n.trailUsfsNumber('${t.usfsNumber}')
                      : l10n.trailSegmentLength(fmt.distance(t.lengthM)),
                ),
                onTap: () => onTap(t),
              ),
          ],
        ),
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
