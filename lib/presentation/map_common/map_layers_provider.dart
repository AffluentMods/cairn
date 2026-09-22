// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_providers.dart';

/// Overlays the user can toggle on the map. The base style (outdoors/topo/
/// satellite) is separate; these ride on top of any base.
enum MapOverlay { trails, pois, fires, land }

const _kEnabledLayers = 'map.layers';

/// The key these layers were saved under before 2026-09-21. The raster overlay
/// controller saved its own list under the same key, so switching radar or
/// slope on or off overwrote this set and silently turned trails and POIs off
/// (no trails drawn, none fetched). Read once for migration, never written.
const legacyLayersKey = 'map.overlays';

/// Trails and points on by default; fires and land (Phase 7) off until the
/// user asks, so the first paint is calm.
const defaultMapLayers = {MapOverlay.trails, MapOverlay.pois};

/// The layer set to start from, given the value under the current key and the
/// legacy shared key. A legacy list holding no layer names at all is what the
/// key collision left behind (an empty list, or only raster overlay keys such
/// as "radar"), so it restores the defaults rather than a map with no trails.
Set<MapOverlay> restoreMapLayers(List<String>? current, List<String>? legacy) {
  Set<MapOverlay> parse(List<String> names) => {
        for (final n in names)
          for (final o in MapOverlay.values)
            if (o.name == n) o,
      };
  if (current != null) return parse(current);
  if (legacy != null) {
    final layers = parse(legacy);
    if (layers.isNotEmpty) return layers;
  }
  return {...defaultMapLayers};
}

/// Which overlays are currently shown. Persisted under its own key.
class MapLayersNotifier extends Notifier<Set<MapOverlay>> {
  @override
  Set<MapOverlay> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return restoreMapLayers(
      prefs.getStringList(_kEnabledLayers),
      prefs.getStringList(legacyLayersKey),
    );
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

const _kContours = 'map.contours';

/// Contour lines traced on the device from the terrain tiles (docs/DECISIONS.md).
/// On by default; persisted. The Topo base map carries its own contours, so
/// the map screens skip tracing there whatever this says.
class ContoursNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_kContours) ?? true;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(_kContours, on);
  }
}

final contoursEnabledProvider =
    NotifierProvider<ContoursNotifier, bool>(ContoursNotifier.new);
