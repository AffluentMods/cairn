// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/geo/haversine.dart';
import '../../../core/geo/nearest_point.dart';
import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/theme/cairn_colors.dart';
import '../../../core/units/unit_formatter.dart';
import '../../../core/worker/geo_worker.dart';
import '../../../data/data_providers.dart';
import '../../../domain/models/poi.dart';
import '../../../domain/usecases/compute_route_stats.dart';
import '../../../domain/usecases/select_route_section.dart';
import '../../../domain/usecases/trail_rating.dart';
import '../../../l10n/app_localizations.dart';
import '../../map_common/map_providers.dart';
import '../../map_common/widgets/elevation_profile.dart';
import '../../navigate/navigate_providers.dart';
import '../../navigate/route_editor_provider.dart';
import '../../saved/library_providers.dart';
import '../../shared/stat_tile.dart';
import '../highlight_provider.dart';
import '../nearby_trails_provider.dart';

/// The trail detail sheet (Addendum A4.1, AllTrails benchmark section 5): the
/// whole named trail with a planning strip (length one way, gain, loss, high
/// point), a difficulty band with its inputs, the route type, typical and fit
/// times, the trail's tags, its elevation profile, the sights and water along
/// it, and parking at the start. The DEM-based parts load after the sheet
/// opens; everything else is instant and offline.
Future<void> showTrailDetail(BuildContext context, NearbyTrail trail) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrailDetailSheet(trail: trail),
  );
}

String sacLabel(AppLocalizations l10n, String? sac) => switch (sac) {
      'hiking' => l10n.sacHiking,
      'mountain_hiking' => l10n.sacMountainHiking,
      'demanding_mountain_hiking' => l10n.sacDemandingMountainHiking,
      'alpine_hiking' => l10n.sacAlpineHiking,
      'demanding_alpine_hiking' => l10n.sacDemandingAlpineHiking,
      'difficult_alpine_hiking' => l10n.sacDifficultAlpineHiking,
      _ => '',
    };

String poiKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
      'peak' => l10n.poiKindPeak,
      'saddle' => l10n.poiKindSaddle,
      'viewpoint' => l10n.poiKindViewpoint,
      'spring' => l10n.poiKindSpring,
      'water' => l10n.poiKindWater,
      'drinking_water' => l10n.poiKindDrinkingWater,
      'camp_site' => l10n.poiKindCampSite,
      'hut' => l10n.poiKindHut,
      'shelter' => l10n.poiKindShelter,
      'toilets' => l10n.poiKindToilets,
      'parking' => l10n.poiKindParking,
      'trailhead' => l10n.poiKindTrailhead,
      'stream' => l10n.poiKindStream,
      'river' => l10n.poiKindRiver,
      _ => kind,
    };

IconData poiKindIcon(String kind) => switch (kind) {
      'peak' => Icons.terrain,
      'saddle' => Icons.landscape_outlined,
      'viewpoint' => Icons.visibility_outlined,
      'spring' ||
      'water' ||
      'drinking_water' ||
      'stream' ||
      'river' =>
        Icons.water_drop_outlined,
      'camp_site' => Icons.holiday_village_outlined,
      'hut' || 'shelter' => Icons.cabin_outlined,
      'toilets' => Icons.wc_outlined,
      'parking' => Icons.local_parking,
      'trailhead' => Icons.signpost_outlined,
      _ => Icons.place_outlined,
    };

/// A point of interest near the line and how far along it lies.
typedef TrailSight = ({PoiPoint poi, double alongM});

/// The POI part of the sheet: sights within 100 m of the line in walking
/// order, and parking or a trailhead within 300 m of the start. Pure and
/// top-level so it runs in a worker isolate.
({List<TrailSight> sights, PoiPoint? parking, double? parkingM})
    matchPoisToTrail(List<PoiPoint> pois, List<List<double>> line) {
  if (line.length < 2) return (sights: const [], parking: null, parkingM: null);
  const sightKinds = {
    'peak',
    'saddle',
    'viewpoint',
    'spring',
    'water',
    'drinking_water',
    'camp_site',
    'hut',
    'shelter',
  };
  var minLat = line.first[0], maxLat = line.first[0];
  var minLon = line.first[1], maxLon = line.first[1];
  for (final p in line) {
    if (p[0] < minLat) minLat = p[0];
    if (p[0] > maxLat) maxLat = p[0];
    if (p[1] < minLon) minLon = p[1];
    if (p[1] > maxLon) maxLon = p[1];
  }
  const pad = 0.002; // about 200 m
  final cum = List<double>.filled(line.length, 0);
  for (var i = 1; i < line.length; i++) {
    cum[i] = cum[i - 1] +
        haversineMeters(line[i - 1][0], line[i - 1][1], line[i][0], line[i][1]);
  }

  final sights = <TrailSight>[];
  PoiPoint? parking;
  var parkingM = double.infinity;
  for (final poi in pois) {
    if (poi.lat < minLat - pad ||
        poi.lat > maxLat + pad ||
        poi.lon < minLon - pad ||
        poi.lon > maxLon + pad) {
      continue;
    }
    if (poi.kind == 'parking' || poi.kind == 'trailhead') {
      final d = haversineMeters(line.first[0], line.first[1], poi.lat, poi.lon);
      if (d <= 300 && d < parkingM) {
        parking = poi;
        parkingM = d;
      }
      continue;
    }
    if (!sightKinds.contains(poi.kind)) continue;
    final np = nearestPointOnPolyline(poi.lat, poi.lon, line);
    if (np == null || np.distanceM > 100) continue;
    final seg = cum[np.segmentIndex + 1] - cum[np.segmentIndex];
    sights.add((poi: poi, alongM: cum[np.segmentIndex] + np.t * seg));
  }
  sights.sort((a, b) => a.alongM.compareTo(b.alongM));
  return (
    sights: sights.take(12).toList(),
    parking: parking,
    parkingM: parking == null ? null : parkingM,
  );
}

class _Insights {
  const _Insights({
    required this.stats,
    required this.sights,
    required this.parking,
    required this.parkingM,
  });
  final RouteStats stats;
  final List<TrailSight> sights;
  final PoiPoint? parking;
  final double? parkingM;
}

class _TrailDetailSheet extends ConsumerStatefulWidget {
  const _TrailDetailSheet({required this.trail});

  final NearbyTrail trail;

  @override
  ConsumerState<_TrailDetailSheet> createState() => _TrailDetailSheetState();
}

class _TrailDetailSheetState extends ConsumerState<_TrailDetailSheet> {
  late final Future<_Insights?> _insights = _load();

  NearbyTrail get trail => widget.trail;

  Future<_Insights?> _load() async {
    final line = trail.navGeometry;
    if (line.length < 2) return null;
    try {
      final stats =
          await computeRouteStats(line, ref.read(elevationRepositoryProvider));
      var minLat = line.first[0], maxLat = line.first[0];
      var minLon = line.first[1], maxLon = line.first[1];
      for (final p in line) {
        if (p[0] < minLat) minLat = p[0];
        if (p[0] > maxLat) maxLat = p[0];
        if (p[1] < minLon) minLon = p[1];
        if (p[1] > maxLon) maxLon = p[1];
      }
      final pois = await ref.read(poiRepositoryProvider).poisInBbox(
        [minLat - 0.003, minLon - 0.003, maxLat + 0.003, maxLon + 0.003],
      );
      final matched = await GeoWorker.run(
        'trail-sights',
        () => matchPoisToTrail(pois, line),
      );
      return _Insights(
        stats: stats,
        sights: matched.sights,
        parking: matched.parking,
        parkingM: matched.parkingM,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cairn = context.cairn;
    final sac = sacLabel(l10n, trail.sacScale);
    final saved =
        (ref.watch(savedTrailIdsProvider).valueOrNull ?? const <String>{})
            .contains(trail.id);
    final line = trail.navGeometry;
    final routeType = routeTypeOf(line);
    final lengthM = polylineLengthMeters(line);
    final visibility = trail.trailVisibility;
    final chainedAll = lengthM >= trail.lengthM * 0.95;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.55, 0.95],
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<_Insights?>(
            future: _insights,
            builder: (context, snap) {
              final insights = snap.data;
              final stats = insights?.stats;
              final loading = snap.connectionState != ConnectionState.done;
              TrailDifficulty? difficulty;
              double? score;
              if (stats != null) {
                score = difficultyScore(
                    distanceM: stats.distanceM, gainM: stats.gainM);
                difficulty = difficultyLevel(
                  score,
                  sacScale: trail.sacScale,
                  trailVisibility: visibility,
                );
              }
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          trail.name.isEmpty ? l10n.trailUnnamed : trail.name,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (trail.usfsNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child:
                                Text(l10n.trailUsfsNumber(trail.usfsNumber!)),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          color:
                              saved ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                        tooltip: saved ? l10n.trailUnsave : l10n.trailSave,
                        onPressed: () => _toggleSave(l10n),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Chips: difficulty (with its inputs as a tooltip), route
                  // type, then the trail's own tags.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (difficulty != null && score != null && stats != null)
                        Tooltip(
                          message: l10n.trailDifficultyWhy(
                            score.round(),
                            fmt.distance(stats.distanceM),
                            fmt.elevation(stats.gainM),
                          ),
                          child: _Chip(
                            text: _difficultyLabel(l10n, difficulty),
                            dot: switch (difficulty) {
                              TrailDifficulty.easy => cairn.track,
                              TrailDifficulty.moderate => cairn.accent,
                              TrailDifficulty.hard => scheme.error,
                              TrailDifficulty.strenuous => scheme.error,
                            },
                          ),
                        )
                      else if (loading)
                        const _Chip(text: '...'),
                      _Chip(
                        text: switch (routeType) {
                          RouteType.loop => l10n.trailRouteLoop,
                          RouteType.outAndBack => l10n.trailRouteOutAndBack,
                          RouteType.pointToPoint => l10n.trailRoutePointToPoint,
                        },
                      ),
                      if (sac.isNotEmpty) _Chip(text: sac),
                      if (visibility == 'intermediate')
                        _Chip(text: l10n.trailVisibilityFaint)
                      else if (visibility == 'bad' ||
                          visibility == 'horrible' ||
                          visibility == 'no')
                        _Chip(text: l10n.trailVisibilityUnmarked),
                      for (final s in trail.surfaces.take(2))
                        _Chip(text: l10n.trailSurface(s)),
                      if (trail.informal) _Chip(text: l10n.trailInformal),
                      if (trail.sectionInView)
                        _Chip(text: l10n.exploreSectionInView),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: fmt.distance(lengthM),
                          label: l10n.trailLengthOneWay(''),
                          compact: true,
                        ),
                      ),
                      Expanded(
                        child: StatTile(
                          value: stats == null
                              ? (loading ? '...' : l10n.statEmpty)
                              : fmt.elevationSigned(stats.gainM),
                          label: l10n.statGain,
                          compact: true,
                        ),
                      ),
                      Expanded(
                        child: StatTile(
                          value: stats == null
                              ? (loading ? '...' : l10n.statEmpty)
                              : fmt.elevation(stats.lossM),
                          label: l10n.statLoss,
                          compact: true,
                        ),
                      ),
                      Expanded(
                        child: StatTile(
                          value: stats == null
                              ? (loading ? '...' : l10n.statEmpty)
                              : fmt.elevation(stats.maxElevM),
                          label: l10n.statHighPoint,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (context) {
                      final band = hoursBand(typicalTimeSeconds(
                        distanceM: stats.distanceM,
                        gainM: stats.gainM,
                      ));
                      String h(double v) => v == v.roundToDouble()
                          ? v.round().toString()
                          : v.toStringAsFixed(1);
                      return Text(
                        '${l10n.trailTimeTypical(l10n.trailHoursBand(h(band.from), h(band.to)))}  ·  '
                        '${l10n.trailTimeFit(UnitFormatter.durationHm(stats.estimatedTime))}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      );
                    }),
                  ],
                  if (!chainedAll)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.trailGapNote,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _navigate(l10n),
                          child: Text(l10n.trailNavigate),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _fitTrail(context),
                        child: Text(l10n.trailShowRoute),
                      ),
                    ],
                  ),
                  if (stats != null && stats.profile.length >= 2) ...[
                    const SizedBox(height: 16),
                    ElevationProfile(profile: stats.profile),
                  ] else if (loading) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.trailProfileLoading,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                  if (insights != null && insights.parking != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.local_parking,
                              size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.trailParkingNear(
                                  fmt.distance(insights.parkingM ?? 0)),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (insights != null && insights.sights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(l10n.trailSights, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    for (final s in insights.sights)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(poiKindIcon(s.poi.kind),
                                size: 18, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.poi.name ?? poiKindLabel(l10n, s.poi.kind),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              fmt.distance(s.alongM),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _difficultyLabel(AppLocalizations l10n, TrailDifficulty d) =>
      switch (d) {
        TrailDifficulty.easy => l10n.trailDifficultyEasy,
        TrailDifficulty.moderate => l10n.trailDifficultyModerate,
        TrailDifficulty.hard => l10n.trailDifficultyHard,
        TrailDifficulty.strenuous => l10n.trailDifficultyStrenuous,
      };

  void _toggleSave(AppLocalizations l10n) {
    ref.read(favoritesRepositoryProvider).toggle(
          trailId: trail.id,
          name: trail.name.isEmpty ? l10n.trailUnnamed : trail.name,
          centerLat: trail.centerLat,
          centerLon: trail.centerLon,
          lengthM: trail.lengthM,
        );
  }

  /// Loads the chained trail into Navigate, picking a sensible section and
  /// orienting it to start near the user (Fix Pass 1 X2.2).
  Future<void> _navigate(AppLocalizations l10n) async {
    final vp = ref.read(viewportProvider);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    Position? last;
    try {
      last = await Geolocator.getLastKnownPosition();
    } on Object {
      last = null;
    }
    var section = selectRouteSection(
      trail.navGeometry,
      viewportBbox: vp?.bbox,
      userLat: last?.latitude,
      userLon: last?.longitude,
    );
    // Planning from afar: start at the parking, else at the low end.
    final insights = await _insights;
    final profile = insights?.stats.profile;
    final reversedByUser = !identical(section.first, trail.navGeometry.first);
    double? startElev;
    double? endElev;
    if (profile != null && profile.length >= 2) {
      startElev = reversedByUser ? profile.last.elevM : profile.first.elevM;
      endElev = reversedByUser ? profile.first.elevM : profile.last.elevM;
    }
    section = orientForPlanning(
      section,
      userLat: last?.latitude,
      userLon: last?.longitude,
      parkingLat: insights?.parking?.lat,
      parkingLon: insights?.parking?.lon,
      startElevM: startElev,
      endElevM: endElev,
    );
    ref.read(routeStartDistanceProvider.notifier).state =
        (last != null && section.length >= 2)
            ? haversineMeters(
                last.latitude,
                last.longitude,
                section.first[0],
                section.first[1],
              )
            : null;
    await ref.read(routeEditorProvider.notifier).loadPolyline(section);
    ref.read(activeRouteNameProvider.notifier).state =
        trail.name.isEmpty ? l10n.trailUnnamed : trail.name;
    ref.read(fitRouteProvider.notifier).state++;
    navigator.pop();
    router.go('/navigate');
  }

  Future<void> _fitTrail(BuildContext context) async {
    final controller = ref.read(mapControllerProvider);
    final geometry = trail.geometry;
    if (controller == null || geometry.isEmpty) return;
    // Highlight the trail on Explore so "Show route" actually shows something,
    // then fit the camera to it (Fix Pass 1 X2.7).
    ref.read(highlightRouteProvider.notifier).state = trail.navGeometry;
    var minLat = geometry.first[0], maxLat = geometry.first[0];
    var minLon = geometry.first[1], maxLon = geometry.first[1];
    for (final p in geometry) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }
    Navigator.of(context).pop();
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        left: 40,
        right: 40,
        top: 80,
        bottom: 200,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.dot});
  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
