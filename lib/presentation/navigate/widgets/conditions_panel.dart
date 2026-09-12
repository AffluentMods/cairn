// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/geo/moon.dart';
import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/data_providers.dart';
import '../../../data/purchases/purchases.dart';
import '../../../domain/models/air_quality.dart';
import '../../../domain/models/fire_incident.dart';
import '../../../domain/models/land_unit.dart';
import '../../../domain/repositories/conditions_repository.dart';
import '../../../domain/usecases/campsites_along_route.dart';
import '../../../domain/usecases/compute_route_stats.dart';
import '../../../domain/usecases/water_along_route.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/widgets/trail_detail_sheet.dart' show poiKindLabel;
import '../../shared/fire_format.dart';
import '../../shared/inciweb_button.dart';
import '../../shared/sparkline.dart';
import '../../shared/time_ago.dart';

typedef _PanelData = ({
  ConditionsBundle bundle,
  List<WaterPoint> water,
  List<CampPoint> camps,
});

/// Opens the conditions panel for a route (spec Phase 7). trailhead is the route
/// start; high is the highest point.
Future<void> showConditions(
  BuildContext context, {
  required String name,
  required List<List<double>> routePolyline,
  required double trailheadLat,
  required double trailheadLon,
  required double trailheadElevM,
  required double highLat,
  required double highLon,
  required double highElevM,
  required List<double> bbox,
  List<ProfilePoint> profile = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ConditionsPanel(
      name: name,
      routePolyline: routePolyline,
      trailheadLat: trailheadLat,
      trailheadLon: trailheadLon,
      trailheadElevM: trailheadElevM,
      highLat: highLat,
      highLon: highLon,
      highElevM: highElevM,
      bbox: bbox,
      profile: profile,
    ),
  );
}

Color aqiColor(AqiCategory c) => switch (c) {
      AqiCategory.good => AppColors.aqiGood,
      AqiCategory.moderate => AppColors.aqiModerate,
      AqiCategory.usg => AppColors.aqiUsg,
      AqiCategory.unhealthy => AppColors.aqiUnhealthy,
      AqiCategory.veryUnhealthy => AppColors.aqiVeryUnhealthy,
      AqiCategory.hazardous => AppColors.aqiHazardous,
    };

String aqiLabel(AppLocalizations l10n, AqiCategory c) => switch (c) {
      AqiCategory.good => l10n.aqiGood,
      AqiCategory.moderate => l10n.aqiModerate,
      AqiCategory.usg => l10n.aqiUsg,
      AqiCategory.unhealthy => l10n.aqiUnhealthy,
      AqiCategory.veryUnhealthy => l10n.aqiVeryUnhealthy,
      AqiCategory.hazardous => l10n.aqiHazardous,
    };

String moonPhaseLabel(AppLocalizations l10n, MoonPhase p) => switch (p) {
      MoonPhase.newMoon => l10n.moonNew,
      MoonPhase.waxingCrescent => l10n.moonWaxingCrescent,
      MoonPhase.firstQuarter => l10n.moonFirstQuarter,
      MoonPhase.waxingGibbous => l10n.moonWaxingGibbous,
      MoonPhase.full => l10n.moonFull,
      MoonPhase.waningGibbous => l10n.moonWaningGibbous,
      MoonPhase.lastQuarter => l10n.moonLastQuarter,
      MoonPhase.waningCrescent => l10n.moonWaningCrescent,
    };

class _ConditionsPanel extends ConsumerStatefulWidget {
  const _ConditionsPanel({
    required this.name,
    required this.routePolyline,
    required this.trailheadLat,
    required this.trailheadLon,
    required this.trailheadElevM,
    required this.highLat,
    required this.highLon,
    required this.highElevM,
    required this.bbox,
    required this.profile,
  });

  final String name;
  final List<List<double>> routePolyline;
  final double trailheadLat;
  final double trailheadLon;
  final double trailheadElevM;
  final double highLat;
  final double highLon;
  final double highElevM;
  final List<double> bbox;
  final List<ProfilePoint> profile;

  @override
  ConsumerState<_ConditionsPanel> createState() => _ConditionsPanelState();
}

class _ConditionsPanelState extends ConsumerState<_ConditionsPanel> {
  late final Future<_PanelData> _future = _load();

  Future<_PanelData> _load() async {
    final bundle = await ref.read(conditionsRepositoryProvider).forRoute(
          routePolyline: widget.routePolyline,
          trailheadLat: widget.trailheadLat,
          trailheadLon: widget.trailheadLon,
          trailheadElevM: widget.trailheadElevM,
          highLat: widget.highLat,
          highLon: widget.highLon,
          highElevM: widget.highElevM,
          bbox: widget.bbox,
        );
    final pois = await ref.read(poiRepositoryProvider).poisInBbox(widget.bbox);
    final candidates = [
      for (final p in pois)
        if (waterKinds.contains(p.kind))
          WaterCandidate(lat: p.lat, lon: p.lon, kind: p.kind, name: p.name),
    ];
    final water = waterAlongRoute(
      widget.routePolyline,
      candidates,
      profile: widget.profile,
    );
    final camps = campsitesAlongRoute(widget.routePolyline, [
      for (final p in pois)
        if (campKinds.contains(p.kind))
          CampCandidate(lat: p.lat, lon: p.lon, kind: p.kind, name: p.name),
    ]);
    return (bundle: bundle, water: water, camps: camps);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return FutureBuilder<_PanelData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!;
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: _sections(context, data.bundle, data.water, data.camps),
            );
          },
        );
      },
    );
  }

  List<Widget> _sections(
    BuildContext context,
    ConditionsBundle b,
    List<WaterPoint> water,
    List<CampPoint> camps,
  ) {
    final l10n = context.l10n;
    final fmt = ref.read(unitFormatterProvider);
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.condTitle(widget.name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            l10n.condUpdatedAgo(_ago(b.fetchedAt)),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (b.stale) ...[
            const SizedBox(width: 6),
            _StaleChip(label: l10n.condStale),
          ],
        ],
      ),
      const Divider(),
      ..._fires(context, b, l10n),
      ..._aqi(context, b, l10n),
      ..._alerts(context, b),
      ..._weather(context, b, l10n, fmt),
      _daylight(context, b, l10n),
      ..._land(context, b, l10n),
      ..._restrictions(context, b, l10n),
      ..._water(context, water, l10n, fmt),
      ..._camps(context, b, camps, l10n, fmt),
    ];
  }

  /// Camps within 300 m of the route with distance along it (spec Phase 8),
  /// plus the wilderness reminder when the route enters one. Shares the
  /// water helper's Summit gate; the water section already shows the pitch.
  List<Widget> _camps(
    BuildContext c,
    ConditionsBundle b,
    List<CampPoint> camps,
    AppLocalizations l10n,
    dynamic fmt,
  ) {
    if (camps.isEmpty || !ref.read(summitUnlockedProvider)) return const [];
    final inWilderness = b.land.any((u) => u.kind == LandKind.wilderness);
    return [
      const Divider(),
      Text(l10n.planCampsHeader, style: Theme.of(c).textTheme.titleSmall),
      for (final camp in camps)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${fmt.distance(camp.distanceAlongM)}  '
            '${camp.name ?? poiKindLabel(l10n, camp.kind)}',
            style: Theme.of(c).textTheme.bodySmall,
          ),
        ),
      if (inWilderness)
        Text(
          l10n.planCampWildernessReminder,
          style: Theme.of(c).textTheme.labelSmall,
        ),
    ];
  }

  List<Widget> _restrictions(
    BuildContext c,
    ConditionsBundle b,
    AppLocalizations l10n,
  ) {
    if (b.restrictions.isEmpty) return const [];
    return [
      for (final r in b.restrictions)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department,
                  size: 14, color: AppColors.smoke),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${r.name}  ${l10n.condRestrictionStage(r.stage)}: ${r.summary}',
                  style: Theme.of(c).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _water(
    BuildContext c,
    List<WaterPoint> water,
    AppLocalizations l10n,
    dynamic fmt,
  ) {
    if (water.isEmpty) return const [];
    // Summit gate: the water and campsite helper (spec Section 12.4).
    if (!ref.read(summitUnlockedProvider)) {
      return [
        const Divider(),
        Text(l10n.planWaterHeader, style: Theme.of(c).textTheme.titleSmall),
        Text(
          '${l10n.summitFeatureWater} (${l10n.summitTitle})',
          style: Theme.of(c).textTheme.bodySmall,
        ),
      ];
    }
    return [
      const Divider(),
      Text(l10n.planWaterHeader, style: Theme.of(c).textTheme.titleSmall),
      for (final w in water)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${fmt.distance(w.distanceAlongM)}  ${w.name ?? w.kind}'
            '${w.lastBeforeClimb ? '  (${l10n.planWaterLastBeforeClimb})' : ''}',
            style: Theme.of(c).textTheme.bodySmall,
          ),
        ),
      Text(
        l10n.planWaterSeasonal,
        style: Theme.of(c).textTheme.labelSmall,
      ),
    ];
  }

  List<Widget> _fires(
      BuildContext c, ConditionsBundle b, AppLocalizations l10n) {
    final fmt = ref.read(unitFormatterProvider);
    final nearest = b.nearestFire;
    final Widget summary;
    if (nearest == null) {
      summary = _line(Icons.check_circle, AppColors.aqiGood, l10n.condFireNone);
    } else if (nearest.crossesRoute) {
      summary = _line(Icons.local_fire_department, AppColors.fire,
          l10n.condFireCrosses(nearest.name));
    } else {
      final d = nearest.distanceToRouteM ?? 0;
      final color = d < 16093 ? AppColors.smoke : AppColors.aqiGood;
      // A single point means "conditions here", not a route.
      final text = widget.routePolyline.length < 2
          ? l10n.condFireDistanceHere(nearest.name, fmt.distance(d))
          : l10n.condFireDistance(nearest.name, fmt.distance(d));
      summary = _line(Icons.local_fire_department, color, text);
    }
    return [
      summary,
      for (final f in b.fires.take(5)) _fireCard(c, f, l10n),
      const SizedBox(height: 8),
    ];
  }

  Widget _fireCard(BuildContext c, FireIncident f, AppLocalizations l10n) {
    final parts = <String>[
      if (f.acres != null) l10n.condFireAcres(formatAcres(f.acres!)),
      if (f.percentContained != null)
        l10n.condFireContained(f.percentContained!),
      if (f.modifiedAt != null) l10n.condUpdatedAgo(_ago(f.modifiedAt!)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: f.prescribed ? AppColors.smoke : AppColors.fire,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(f.name)),
              InciwebButton(fire: f),
            ],
          ),
          if (parts.isNotEmpty)
            Text(parts.join('  '), style: Theme.of(c).textTheme.labelSmall),
        ],
      ),
    );
  }

  List<Widget> _aqi(BuildContext c, ConditionsBundle b, AppLocalizations l10n) {
    final aqi = b.aqi;
    if (aqi == null) return const [];
    return [
      Row(
        children: [
          Icon(Icons.air, size: 16, color: aqiColor(aqi.category)),
          const SizedBox(width: 6),
          Text(
              '${l10n.condAqi}: ${aqi.currentAqi} ${aqiLabel(l10n, aqi.category)}'),
        ],
      ),
      // The 3-day hourly forecast as a sparkline (spec Phase 7).
      if (aqi.hourly.length >= 2)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            children: [
              Sparkline(
                values: [
                  for (final p in aqi.hourly.take(72)) p.aqi.toDouble(),
                ],
                width: 120,
                height: 26,
                color: aqiColor(aqi.category),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.condAqiThreeDays,
                style: Theme.of(c).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      Text(
        aqi.source == AqiSource.model ? l10n.condAqiModel : l10n.condAqiMonitor,
        style: Theme.of(c).textTheme.labelSmall,
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _alerts(BuildContext c, ConditionsBundle b) {
    return [
      for (final a in b.alerts)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (a.isRedFlag ? AppColors.fire : AppColors.smoke)
                .withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 16,
                color: a.isRedFlag ? AppColors.fire : AppColors.smoke,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(a.event)),
            ],
          ),
        ),
    ];
  }

  List<Widget> _weather(
    BuildContext c,
    ConditionsBundle b,
    AppLocalizations l10n,
    dynamic fmt,
  ) {
    Widget row(String label, dynamic forecast) {
      if (forecast == null) return const SizedBox.shrink();
      final h = forecast.current;
      if (h == null) return const SizedBox.shrink();
      final wind = h.windMps == null ? '' : ' ${fmt.speed(h.windMps)}';
      final gust = h.gustMps == null ? '' : ' g${fmt.speed(h.gustMps)}';
      final precip =
          h.precipProbability == null ? '' : ' ${h.precipProbability}%';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$label ${fmt.elevation(forecast.elevationM)}  '
          '${fmt.temperature(h.tempC)}$precip$wind$gust',
          style: Theme.of(c).textTheme.bodySmall,
        ),
      );
    }

    return [
      Text(l10n.condWeather, style: Theme.of(c).textTheme.titleSmall),
      row(l10n.condTrailhead, b.weatherTrailhead),
      row(l10n.condHighPoint, b.weatherHigh),
      const SizedBox(height: 8),
    ];
  }

  Widget _daylight(BuildContext c, ConditionsBundle b, AppLocalizations l10n) {
    final s = b.solar;
    final fmtT = DateFormat.jm();
    final sunrise =
        s.sunrise == null ? '--' : fmtT.format(s.sunrise!.toLocal());
    final sunset = s.sunset == null ? '--' : fmtT.format(s.sunset!.toLocal());
    final length = '${s.daylight.inHours}h ${s.daylight.inMinutes % 60}m';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '${l10n.condDaylight}: ${l10n.condDaylightRange(sunrise, sunset, length)}   '
        '${l10n.condMoon(b.moon.illuminationPercent, moonPhaseLabel(l10n, b.moon.phase))}',
        style: Theme.of(c).textTheme.bodySmall,
      ),
    );
  }

  List<Widget> _land(
      BuildContext c, ConditionsBundle b, AppLocalizations l10n) {
    if (b.land.isEmpty) return const [];
    return [
      const Divider(),
      Text(l10n.condLand, style: Theme.of(c).textTheme.titleSmall),
      for (final u in b.land)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('${u.name}  ${_permit(l10n, u)}',
              style: Theme.of(c).textTheme.bodySmall),
        ),
    ];
  }

  String _permit(AppLocalizations l10n, LandUnit u) => switch (u.kind) {
        LandKind.wilderness => l10n.condWildernessPermit,
        LandKind.nationalPark => l10n.condNpsFee,
        LandKind.forest => l10n.condNwForestPass,
        LandKind.statePark => l10n.condDiscoverPass,
      };

  Widget _line(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text)),
          ],
        ),
      );

  String _ago(DateTime t) => formatAgo(context.l10n, t);
}

class _StaleChip extends StatelessWidget {
  const _StaleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.closure.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
