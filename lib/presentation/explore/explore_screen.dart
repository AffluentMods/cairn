// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/models/fire_incident.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/cairn_map.dart';
import '../map_common/contours_layer_sync.dart';
import '../map_common/map_geojson.dart';
import '../map_common/map_layers_provider.dart';
import '../map_common/map_providers.dart';
import '../map_common/trails_layer_sync.dart';
import '../map_common/widgets/layer_sheet.dart';
import '../map_common/widgets/location_fab.dart';
import '../navigate/navigate_providers.dart';
import '../navigate/user_waypoints_layer.dart';
import '../navigate/widgets/waypoint_editor_sheet.dart';
import '../shell/shell_providers.dart';
import 'highlight_provider.dart';
import 'nearby_trails_provider.dart';
import 'trail_load_status.dart';
import 'widgets/fire_card_sheet.dart';
import 'widgets/trail_card.dart';
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

  /// Bumped whenever the viewport or layer set changes. A refresh captures the
  /// value at its start and abandons its result the moment this moves on, so a
  /// slow fetch never paints a stale viewport (Fix Pass 1 X1.3.2).
  int _generation = 0;

  /// Last applied source signatures, so an unchanged set is not rebuilt and
  /// re-sent over the platform channel (Fix Pass 1 X1.3.4). Null means the
  /// source is currently cleared.
  int? _trailsSig;
  int? _poisSig;

  /// What the contour source holds ('' when cleared); null on a fresh style.
  String? _contoursSig;

  /// The fires currently drawn, so a tap on a flame or perimeter can open
  /// the incident's card.
  List<FireIncident> _fires = const [];

  MapLibreMapController? get _controller => ref.read(mapControllerProvider);

  Future<void> _onStyleLoaded(MapLibreMapController c) async {
    // A fresh style (tab switch, base-map change) starts with empty sources,
    // so the "already sent" signatures must not skip the first fill.
    _trailsSig = null;
    _poisSig = null;
    _contoursSig = null;
    await _installHighlight(c);
    await _applyHighlight();
    await _installUserWaypoints(c);
    await _refreshOverlays();
  }

  /// The user's own pins (Addendum A4.5) show on Explore too, above the POIs,
  /// so a saved water source or camp is visible while planning.
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
      await _refreshUserWaypoints();
    }
  }

  Future<void> _refreshUserWaypoints() async {
    final c = _controller;
    if (c == null) return;
    final wps =
        ref.read(userWaypointsProvider).valueOrNull ?? const <UserWaypoint>[];
    try {
      await c.setGeoJsonSource(
          'cairn-user-waypoints', userWaypointsGeoJson(wps));
    } catch (_) {
      // The source is installed on style load; a miss here is harmless.
    }
  }

  /// Adds the "Show route" highlight source and its casing + line layers. They
  /// sit on top of the trails so the chosen trail stands out (Fix Pass 1 X2.7).
  Future<void> _installHighlight(MapLibreMapController c) async {
    try {
      await c.addSource(
        'cairn-highlight',
        const GeojsonSourceProperties(
          data: {'type': 'FeatureCollection', 'features': <dynamic>[]},
        ),
      );
      await c.addLineLayer(
        'cairn-highlight',
        'cairn-highlight-casing',
        const LineLayerProperties(
          lineColor: '#FFFFFF',
          lineWidth: 8.0,
          lineOpacity: 0.9,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      await c.addLineLayer(
        'cairn-highlight',
        'cairn-highlight-line',
        const LineLayerProperties(
          lineColor: '#2E90FA',
          lineWidth: 4.0,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
    } catch (_) {
      // Already installed on this style; the data refresh below covers it.
    }
  }

  Future<void> _applyHighlight() async {
    final controller = _controller;
    if (controller == null) return;
    final geom = ref.read(highlightRouteProvider);
    try {
      await controller.setGeoJsonSource(
        'cairn-highlight',
        geom == null ? emptyFeatureCollection() : lineToGeoJson(geom),
      );
    } catch (_) {
      // The source may not exist yet on a fresh style; install covers it.
    }
  }

  Future<void> _onCameraIdle(MapLibreMapController c) async {
    _generation++;
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
    final gen = _generation;
    // True once the viewport has moved on, so we neither paint a stale frame
    // nor loop forever: the pending re-run picks up the new viewport.
    bool stale() => gen != _generation;
    final status = ref.read(trailLoadStatusProvider.notifier);
    try {
      final layers = ref.read(mapLayersProvider);
      // A wide view spans dozens of z10 cells (one Overpass query each, about
      // 20 miles square). Fetch up to a 4 by 4 block, center first, painting
      // each cell as it lands; further out, draw what is cached and the list
      // says "zoom in". The pass stops when the view moves on.
      final fetchCells = viewportFetchesCells(viewport);
      final settled =
          fetchCells ? TrailLoadStatus.idle : TrailLoadStatus.tooWide;

      if (layers.contains(MapOverlay.trails)) {
        status.state = settled;
        final synced = await syncTrailsLayer(
          controller: controller,
          viewport: viewport,
          repo: ref.read(trailRepositoryProvider),
          previousSig: _trailsSig,
          isStale: stale,
          fetch: fetchCells,
          onProgress: (done, total, fetched) async {
            if (!mounted || stale()) return;
            status.state = done < total
                ? TrailLoadStatus.loading(done, total)
                : TrailLoadStatus.idle;
            // Grow the "Trails in view" list with each cell, so the nearest
            // trails are listed while the outer cells still load.
            if (fetched) ref.invalidate(nearbyTrailsProvider);
          },
        );
        if (synced == null) return;
        _trailsSig = synced.sig;
        status.state = settled;
        // Rebuild the "Trails in view" list now that this area is cached, so a
        // cold load does not stay empty until the next pan (Fix Pass 1 X1.3.3).
        ref.invalidate(nearbyTrailsProvider);
        if (mounted && synced.load.networkError && synced.trails.isEmpty) {
          setState(() => _showOfflineBanner = true);
        }
      } else {
        status.state = TrailLoadStatus.idle;
        if (_trailsSig != null) {
          await controller.setGeoJsonSource(
              'cairn-trails', emptyFeatureCollection());
          _trailsSig = null;
        }
      }

      // Contour lines, traced from the terrain tiles for this view.
      final contoursSig = await ref.read(contourLayerSyncProvider).sync(
            controller: controller,
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
      if (contoursSig == null) return;
      _contoursSig = contoursSig;

      if (layers.contains(MapOverlay.pois)) {
        final repo = ref.read(poiRepositoryProvider);
        if (viewportFetchesCells(viewport, maxCells: maxPoiCellsPerRefresh)) {
          await repo.ensureArea(viewport.bbox, isCancelled: stale);
        }
        if (stale()) return;
        final pois = await repo.poisInBbox(viewport.bbox);
        if (stale()) return;
        final sig = poisSignature(pois);
        if (sig != _poisSig) {
          await controller.setGeoJsonSource('cairn-pois', poisToGeoJson(pois));
          _poisSig = sig;
        }
      } else if (_poisSig != null) {
        await controller.setGeoJsonSource(
            'cairn-pois', emptyFeatureCollection());
        _poisSig = null;
      }

      if (layers.contains(MapOverlay.fires)) {
        final fires = await ref
            .read(conditionsRepositoryProvider)
            .firesInBbox(viewport.bbox);
        if (stale()) return;
        _fires = fires;
        await controller.setGeoJsonSource('cairn-fires', firesToGeoJson(fires));
      } else {
        _fires = const [];
        await controller.setGeoJsonSource(
            'cairn-fires', emptyFeatureCollection());
      }

      if (layers.contains(MapOverlay.land)) {
        final land = await ref
            .read(conditionsRepositoryProvider)
            .landInBbox(viewport.bbox);
        if (stale()) return;
        await controller.setGeoJsonSource('cairn-land', landToGeoJson(land));
      } else {
        await controller.setGeoJsonSource(
            'cairn-land', emptyFeatureCollection());
      }
    } finally {
      _refreshing = false;
      // Re-run if a newer viewport/layer change arrived while we were working
      // (either flagged pending, or detected as a generation bump).
      if (_pending || gen != _generation) {
        _pending = false;
        unawaited(_refreshOverlays());
      }
    }
  }

  Future<void> _onMapClick(math.Point<double> point, LatLng latLng) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      // The user's own pin comes first: tapping it opens the editor.
      final pinHits = await controller.queryRenderedFeatures(
          point, ['user-waypoints-layer'], null);
      if (pinHits.isNotEmpty) {
        final props = (pinHits.first as Map)['properties'];
        final id = props is Map ? props['id']?.toString() : null;
        final wps = ref.read(userWaypointsProvider).valueOrNull ??
            const <UserWaypoint>[];
        for (final w in wps) {
          if (w.id == id) {
            if (mounted) {
              await showWaypointEditor(context,
                  lat: w.lat, lon: w.lon, existing: w);
            }
            return;
          }
        }
      }
      // A flame or perimeter wins over the trail under it: the fire is the
      // reason the user is looking (spec Phase 7 tap card).
      if (_fires.isNotEmpty) {
        final hits = await controller.queryRenderedFeatures(
            point, ['fires-point', 'fires-fill'], null);
        if (hits.isNotEmpty) {
          final props = (hits.first as Map)['properties'];
          final id = props is Map ? props['id']?.toString() : null;
          for (final f in _fires) {
            if (f.id == id) {
              if (mounted) await showFireCard(context, f);
              return;
            }
          }
        }
      }
      final features = await controller.queryRenderedFeatures(
          point, ['trails', 'trails-informal'], null);
      if (features.isEmpty) return;
      final props = (features.first as Map)['properties'];
      final id = (props is Map) ? props['id'] : null;
      if (id == null) return;
      final trail =
          await ref.read(trailRepositoryProvider).byId((id as num).toInt());
      if (trail == null || !mounted) return;
      // Open the whole named trail when the list already assembled it, so a
      // tap on one way shows the same entry as the card.
      final nearby = ref.read(nearbyTrailsProvider).valueOrNull?.entries ??
          const <NearbyTrail>[];
      NearbyTrail? entry;
      for (final n in nearby) {
        if (trail.name != null && n.name == trail.name) {
          entry = n;
          break;
        }
      }
      await showTrailDetail(context, entry ?? NearbyTrail.single(trail));
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

    ref.listen(mapLayersProvider, (_, __) {
      _generation++;
      _refreshOverlays();
    });
    // The contour switch and a units change retrace the view.
    ref.listen(contoursEnabledProvider, (_, __) {
      _generation++;
      _refreshOverlays();
    });
    ref.listen(unitFormatterProvider, (_, __) {
      _generation++;
      _refreshOverlays();
    });
    ref.listen(userWaypointsProvider, (_, __) => _refreshUserWaypoints());
    ref.listen(highlightRouteProvider, (_, __) => _applyHighlight());
    final hasHighlight = ref.watch(highlightRouteProvider) != null;
    final load = ref.watch(trailLoadStatusProvider);

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
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.search),
                tooltip: context.l10n.exploreSearchHint,
                onPressed: () => showTrailSearch(context),
              ),
            ),
          ),
          Positioned(
              top: topInset + 8, right: 12, child: const LayerSwitcherButton()),
          if (load.isLoading)
            Positioned(
              top: topInset + 16,
              left: 72,
              right: 72,
              child: Center(
                child: _LoadingPill(done: load.done, total: load.total),
              ),
            ),
          const Positioned(right: 16, bottom: 200, child: LocationFab()),
          if (hasHighlight)
            Positioned(
              left: 0,
              right: 0,
              bottom: 190,
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.close, size: 18),
                  label: Text(context.l10n.genericClear),
                  onPressed: () =>
                      ref.read(highlightRouteProvider.notifier).state = null,
                ),
              ),
            ),
          if (_showOfflineBanner)
            Positioned(
              top: topInset + 60,
              left: 12,
              right: 12,
              child: _OfflineBanner(
                onDismiss: () => setState(() => _showOfflineBanner = false),
              ),
            ),
          const _NearbyTrailsSheet(),
        ],
      ),
    );
  }
}

class _NearbyTrailsSheet extends ConsumerWidget {
  const _NearbyTrailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final nearby = ref.watch(nearbyTrailsProvider).valueOrNull;
    final trails = nearby?.entries ?? const <NearbyTrail>[];
    final load = ref.watch(trailLoadStatusProvider);
    final note = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        );
    // Why the list is empty, or what it leaves out, in the user's terms.
    final String? emptyText = trails.isNotEmpty
        ? null
        : switch (load.phase) {
            TrailLoadPhase.loading => l10n.exploreLoadingTrailsList,
            TrailLoadPhase.tooWide => l10n.exploreZoomInForTrails,
            TrailLoadPhase.idle => l10n.exploreNoTrailsHere,
          };
    final String? footer = trails.isEmpty
        ? null
        : (nearby?.capped ?? false)
            ? l10n.exploreShowingClosest(trails.length)
            : load.phase == TrailLoadPhase.tooWide
                ? l10n.exploreZoomInForMore
                : null;
    return DraggableScrollableSheet(
      initialChildSize: 0.18,
      minChildSize: 0.18,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.18, 0.5, 0.85],
      builder: (context, scroll) => Material(
        color: scheme.surface,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  if (load.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Text('${nearby?.total ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            if (emptyText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Text(emptyText, style: note),
              ),
            for (final t in trails)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TrailCard(
                  trail: t,
                  onTap: () => showTrailDetail(context, t),
                ),
              ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(footer, style: note),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Loading trails 2/5" while Overpass cells for the view come in, so a slow
/// first load reads as progress rather than an empty map.
class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.exploreLoadingTrails(done, total),
              style: Theme.of(context).textTheme.labelLarge,
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
