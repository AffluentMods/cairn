// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_providers.dart';

/// Overlays the user can toggle on the map. The base style (outdoors/topo/
/// satellite) is separate; these ride on top of any base.
enum MapOverlay { trails, pois, fires, land }

const _kEnabledLayers = 'map.overlays';

/// Which overlays are currently shown. Persisted. Trails and points on by
/// default; fires and land (Phase 7) off until the user asks, so the first
/// paint is calm.
class MapLayersNotifier extends Notifier<Set<MapOverlay>> {
  @override
  Set<MapOverlay> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getStringList(_kEnabledLayers);
    if (stored == null) {
      return {MapOverlay.trails, MapOverlay.pois};
    }
    return stored
        .map((n) => MapOverlay.values.where((o) => o.name == n))
        .expand((e) => e)
        .toSet();
  }

  Future<void> toggle(MapOverlay overlay) async {
    final next = Set<MapOverlay>.from(state);
    if (!next.add(overlay)) next.remove(overlay);
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_kEnabledLayers, next.map((o) => o.name).toList());
  }

  bool isOn(MapOverlay overlay) => state.contains(overlay);
}

final mapLayersProvider =
    NotifierProvider<MapLayersNotifier, Set<MapOverlay>>(MapLayersNotifier.new);
