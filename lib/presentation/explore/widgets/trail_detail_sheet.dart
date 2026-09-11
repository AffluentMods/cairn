// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../data/data_providers.dart';
import '../../../domain/models/trail.dart';
import '../../../l10n/app_localizations.dart';
import '../../map_common/map_providers.dart';
import '../../navigate/navigate_providers.dart';
import '../../navigate/route_editor_provider.dart';
import '../../saved/library_providers.dart';
import '../../shared/stat_tile.dart';

Future<void> showTrailDetail(BuildContext context, Trail trail) {
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

class _TrailDetailSheet extends ConsumerWidget {
  const _TrailDetailSheet({required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final scheme = Theme.of(context).colorScheme;
    final sac = sacLabel(l10n, trail.sacScale);
    final trailId = 'w${trail.id}';
    final saved = (ref.watch(savedTrailIdsProvider).valueOrNull ??
            const <String>{})
        .contains(trailId);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.4, 0.95],
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trail.name ?? l10n.trailUnnamed,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (trail.usfsNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(l10n.trailUsfsNumber(trail.usfsNumber!)),
                    ),
                  IconButton(
                    icon: Icon(
                      saved ? Icons.favorite : Icons.favorite_border,
                      color: saved ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    tooltip: saved ? l10n.trailUnsave : l10n.trailSave,
                    onPressed: () => _toggleSave(ref, l10n),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: fmt.distance(trail.lengthM),
                      label: l10n.trailSegmentLength(''),
                    ),
                  ),
                  if (trail.surface != null)
                    Expanded(
                      child: StatTile(
                        value: trail.surface!,
                        label: 'surface',
                      ),
                    ),
                  if (sac.isNotEmpty)
                    Expanded(child: StatTile(value: sac, label: 'grade')),
                  if (trail.informal)
                    Expanded(
                      child: StatTile(
                        value: l10n.trailInformal,
                        label: 'type',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(routeEditorProvider.notifier)
                            .loadPolyline(trail.geometry);
                        ref.read(activeRouteNameProvider.notifier).state =
                            trail.name ?? l10n.trailUnnamed;
                        ref.read(fitRouteProvider.notifier).state++;
                        Navigator.of(context).pop();
                        context.go('/navigate');
                      },
                      child: Text(l10n.trailNavigate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _fitTrail(ref, context),
                    child: Text(l10n.trailShowRoute),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSave(WidgetRef ref, AppLocalizations l10n) {
    final geo = trail.geometry;
    final mid = geo.isEmpty ? const [0.0, 0.0] : geo[geo.length ~/ 2];
    ref.read(favoritesRepositoryProvider).toggle(
          trailId: 'w${trail.id}',
          name: trail.name ?? l10n.trailUnnamed,
          centerLat: mid[0],
          centerLon: mid[1],
          lengthM: trail.lengthM,
        );
  }

  Future<void> _fitTrail(WidgetRef ref, BuildContext context) async {
    final controller = ref.read(mapControllerProvider);
    if (controller == null || trail.geometry.isEmpty) return;
    var minLat = trail.geometry.first[0], maxLat = trail.geometry.first[0];
    var minLon = trail.geometry.first[1], maxLon = trail.geometry.first[1];
    for (final p in trail.geometry) {
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
