// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/settings.dart';
import '../../../core/settings/settings_providers.dart';
import '../map_layers_provider.dart';

/// The pill button (top of the map) that opens the layer switcher.
class LayerSwitcherButton extends ConsumerWidget {
  const LayerSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final l10n = context.l10n;
    final label = switch (style) {
      CairnMapStyle.outdoors => l10n.styleOutdoors,
      CairnMapStyle.topo => l10n.styleTopo,
      CairnMapStyle.satellite => l10n.styleSatellite,
    };
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showLayerSwitcher(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_outlined, size: 18),
              const SizedBox(width: 6),
              Text(label),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLayerSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _LayerSwitcherSheet(),
  );
}

class _LayerSwitcherSheet extends ConsumerWidget {
  const _LayerSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final overlays = ref.watch(mapLayersProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.layersTitle,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          _StyleTile(
            style: CairnMapStyle.outdoors,
            label: l10n.styleOutdoors,
            selected: style == CairnMapStyle.outdoors,
          ),
          _StyleTile(
            style: CairnMapStyle.topo,
            label: l10n.styleTopo,
            selected: style == CairnMapStyle.topo,
          ),
          _StyleTile(
            style: CairnMapStyle.satellite,
            label: l10n.styleSatellite,
            selected: style == CairnMapStyle.satellite,
          ),
          const Divider(height: 24),
          _OverlaySwitch(
            layer: MapOverlay.trails,
            label: l10n.layerTrails,
            enabled: overlays.contains(MapOverlay.trails),
          ),
          _OverlaySwitch(
            layer: MapOverlay.pois,
            label: l10n.layerPois,
            enabled: overlays.contains(MapOverlay.pois),
          ),
          _OverlaySwitch(
            layer: MapOverlay.fires,
            label: l10n.layerFires,
            enabled: overlays.contains(MapOverlay.fires),
          ),
          _OverlaySwitch(
            layer: MapOverlay.land,
            label: l10n.layerLand,
            enabled: overlays.contains(MapOverlay.land),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StyleTile extends ConsumerWidget {
  const _StyleTile({
    required this.style,
    required this.label,
    required this.selected,
  });

  final CairnMapStyle style;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: () {
        ref.read(settingsProvider.notifier).setMapStyle(style);
        Navigator.of(context).pop();
      },
    );
  }
}

class _OverlaySwitch extends ConsumerWidget {
  const _OverlaySwitch({
    required this.layer,
    required this.label,
    required this.enabled,
  });

  final MapOverlay layer;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: enabled,
      title: Text(label),
      onChanged: (_) => ref.read(mapLayersProvider.notifier).toggle(layer),
    );
  }
}
