// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/net/connectivity_provider.dart';
import '../basemaps/basemap_registry.dart';
import '../map_layers_provider.dart';
import '../map_providers.dart';
import '../overlays/overlay_controller.dart';
import '../overlays/overlay_registry.dart';

/// The round map button that opens the layer sheet, badged with the number of
/// active raster overlays (Addendum A4.2 / A5).
class LayerSwitcherButton extends ConsumerWidget {
  const LayerSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(overlayControllerProvider).length;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: scheme.surface.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showLayerSheet(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.layers_outlined, size: 20),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: scheme.surface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showLayerSheet(BuildContext context) {
  // A DraggableScrollableSheet inside the modal so long content scrolls instead
  // of overflowing (Addendum A5, fix F1).
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scroll) => LayerSheet(scrollController: scroll),
    ),
  );
}

class LayerSheet extends ConsumerWidget {
  const LayerSheet({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = ref.watch(basemapProvider);
    final cairnLayers = ref.watch(mapLayersProvider);
    final activeOverlays = ref.watch(overlayControllerProvider);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _sectionLabel(context, l10n.layersMapType),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [
                  for (final b in basemaps)
                    _BasemapTile(
                      def: b,
                      selected: b.key == selected.key,
                      onTap: () => ref.read(basemapProvider.notifier).select(b),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _TiltTile()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniActionTile(
                      icon: Icons.threed_rotation,
                      label: l10n.nav3dView,
                      trailing: Icon(Icons.chevron_right,
                          size: 18, color: scheme.onSurfaceVariant),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/navigate/3d');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, l10n.layersOverlays),
              const SizedBox(height: 4),
              // Cairn's own GeoJSON layers.
              _CairnLayerRow(
                icon: Icons.route_outlined,
                label: l10n.layerTrails,
                on: cairnLayers.contains(MapOverlay.trails),
                overlay: MapOverlay.trails,
              ),
              _CairnLayerRow(
                icon: Icons.water_drop_outlined,
                label: l10n.layerPois,
                on: cairnLayers.contains(MapOverlay.pois),
                overlay: MapOverlay.pois,
              ),
              _CairnLayerRow(
                icon: Icons.forest_outlined,
                label: l10n.layerLand,
                on: cairnLayers.contains(MapOverlay.land),
                overlay: MapOverlay.land,
              ),
              _CairnLayerRow(
                icon: Icons.local_fire_department_outlined,
                label: l10n.layerFires,
                on: cairnLayers.contains(MapOverlay.fires),
                overlay: MapOverlay.fires,
              ),
              // Runtime raster overlays.
              for (final o in overlays)
                _OverlayRow(def: o, on: activeOverlays.contains(o.key)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}

class _BasemapTile extends StatelessWidget {
  const _BasemapTile({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final BasemapDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final coverage = switch (def.coverage) {
      Coverage.us => l10n.coverageUsOnly,
      Coverage.france => l10n.coverageFranceOnly,
      Coverage.world => '',
    };
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _gradientFor(def.key),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // A real crop of the base map (Addendum A5.2 preview
                  // image); the gradient and icon stay as the fallback.
                  Image.asset(
                    'assets/map_previews/${def.key}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(_iconFor(def.key),
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 22),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.check, size: 12, color: scheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            def.label(l10n),
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(
            height: 14,
            child: coverage.isEmpty
                ? null
                : Text(coverage,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  static LinearGradient _gradientFor(String key) {
    final colors = switch (key) {
      'outdoors' => [const Color(0xFF3B5A3A), const Color(0xFF6E8B57)],
      'topo' => [const Color(0xFFB79A6A), const Color(0xFFD9C6A0)],
      'satellite' => [const Color(0xFF2E3A29), const Color(0xFF4B5B3B)],
      'terrain' => [const Color(0xFF6E7268), const Color(0xFFAFB0A6)],
      'road' => [const Color(0xFF8A8F86), const Color(0xFFC9CBC2)],
      'ign_plan' => [const Color(0xFF8FB08A), const Color(0xFFE4D0C4)],
      _ => [const Color(0xFF3B5A3A), const Color(0xFF6E8B57)],
    };
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static IconData _iconFor(String key) => switch (key) {
        'outdoors' => Icons.terrain,
        'topo' => Icons.map_outlined,
        'satellite' => Icons.satellite_alt_outlined,
        'terrain' => Icons.landscape_outlined,
        'road' => Icons.alt_route,
        'ign_plan' => Icons.grid_on,
        _ => Icons.map_outlined,
      };
}

class _TiltTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final on = ref.watch(tiltProvider);
    return _tileShell(
      context,
      child: Row(
        children: [
          Icon(Icons.landscape, size: 17, color: scheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
              child: Text(l10n.layersTilt,
                  style: const TextStyle(fontSize: 12.5))),
          Switch(
            value: on,
            onChanged: (v) {
              ref.read(tiltProvider.notifier).state = v;
              final c = ref.read(mapControllerProvider);
              c?.animateCamera(CameraUpdate.tiltTo(v ? 60 : 0));
            },
          ),
        ],
      ),
    );
  }
}

class _MiniActionTile extends StatelessWidget {
  const _MiniActionTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _tileShell(
        context,
        child: Row(
          children: [
            Icon(icon, size: 17, color: scheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12.5))),
            trailing,
          ],
        ),
      ),
    );
  }
}

Widget _tileShell(BuildContext context, {required Widget child}) => Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );

class _CairnLayerRow extends ConsumerWidget {
  const _CairnLayerRow({
    required this.icon,
    required this.label,
    required this.on,
    required this.overlay,
  });

  final IconData icon;
  final String label;
  final bool on;
  final MapOverlay overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: on,
      onChanged: (_) => ref.read(mapLayersProvider.notifier).toggle(overlay),
      secondary: Icon(icon, color: scheme.onSurface, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _OverlayRow extends ConsumerWidget {
  const _OverlayRow({required this.def, required this.on});

  final OverlayDef def;
  final bool on;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final coverage = switch (def.coverage) {
      Coverage.us => l10n.coverageUsOnly,
      Coverage.france => l10n.coverageFranceOnly,
      Coverage.world => '',
    };
    // Tiles not reaching the device (offline, service down): the switch stays
    // usable and the row says so (Addendum A5). Offline comes from the
    // device (MapLibre stops fetching then); a dead service from the proxy.
    final needsConnection = on &&
        ((ref.watch(offlineProvider).valueOrNull ?? false) ||
            ref.watch(overlayOfflineProvider).contains(def.key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: on,
          onChanged: (v) =>
              ref.read(overlayControllerProvider.notifier).toggle(def.key, v),
          secondary: Icon(_iconFor(def.key), color: scheme.onSurface, size: 20),
          title: Row(
            children: [
              Flexible(
                  child: Text(def.label(l10n),
                      style: const TextStyle(fontSize: 14))),
              if (coverage.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CoverageChip(text: coverage),
              ],
            ],
          ),
          // The connection chip sits under the subtitle so a long title does
          // not wrap around two chips.
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(def.subtitle(l10n),
                  style: TextStyle(
                      fontSize: 11.5, color: scheme.onSurfaceVariant)),
              if (needsConnection)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _CoverageChip(text: l10n.overlayNeedsConnection),
                ),
            ],
          ),
        ),
        if (on && def.key == 'slope')
          _SlopeLegend(disclaimer: def.disclaimer?.call(l10n)),
      ],
    );
  }

  static IconData _iconFor(String key) => switch (key) {
        'radar' => Icons.water_drop_outlined,
        'temperature' => Icons.thermostat_outlined,
        'snowDepth' => Icons.ac_unit_outlined,
        'slope' => Icons.terrain_outlined,
        'lidarHillshade' => Icons.landscape_outlined,
        'gpsTraces' => Icons.timeline_outlined,
        _ => Icons.layers_outlined,
      };
}

class _CoverageChip extends StatelessWidget {
  const _CoverageChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
    );
  }
}

class _SlopeLegend extends StatelessWidget {
  const _SlopeLegend({this.disclaimer});
  final String? disclaimer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 10, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF2EEDC),
                  Color(0xFFE9C77E),
                  Color(0xFFDB8440),
                  Color(0xFFA33A2F),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (disclaimer != null)
            Text(disclaimer!,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          if (disclaimer == null)
            Text(l10n.overlaySlopeSubtitle,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
