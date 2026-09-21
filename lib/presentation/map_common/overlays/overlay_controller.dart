// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/settings/settings_providers.dart';
import '../map_layers_provider.dart' show legacyLayersKey;
import '../map_providers.dart';
import 'overlay_registry.dart';
import 'tile_proxy.dart';

/// Its own key: the raster overlays used to share `map.overlays` with the
/// Cairn layer toggles (map_layers_provider.dart), and each write here wiped
/// the trails and POI switches.
const _kOverlayPref = 'map.rasterOverlays';

/// The raster overlays to start from, given the value under the current key
/// and the legacy shared `map.overlays` list (which may also hold layer names
/// such as "trails"; only registered overlay keys survive).
Set<String> restoreRasterOverlays(List<String>? current, List<String>? legacy) {
  final saved = current ?? legacy ?? const <String>[];
  return saved.where((k) => overlayByKey(k) != null).toSet();
}

/// Overlay keys whose tiles are not reaching the device right now (Addendum
/// A5: "network overlays stay toggleable but show the subtitle chip"). Fed by
/// the tile proxy, so only proxied overlays report; a direct XYZ overlay has
/// no failure signal from MapLibre.
final overlayOfflineProvider = StateProvider<Set<String>>((ref) {
  final proxy = TileProxy.instance;
  void sync() => ref.controller.state = proxy.offline.value;
  proxy.offline.addListener(sync);
  ref.onDispose(() => proxy.offline.removeListener(sync));
  return proxy.offline.value;
});

/// Tracks which raster overlays are on (persisted) and installs or removes them
/// on the live MapLibre controller. Overlays are reinstalled on every style
/// load (Addendum A5.3) and live ones (radar) refresh on their interval.
class OverlayController extends Notifier<Set<String>> {
  Timer? _refreshTimer;
  final Map<String, DateTime> _installedAt = {};

  @override
  Set<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _refreshTimer ??=
        Timer.periodic(const Duration(minutes: 1), (_) => _refreshDue());
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
    return restoreRasterOverlays(
      prefs.getStringList(_kOverlayPref),
      prefs.getStringList(legacyLayersKey),
    );
  }

  Future<void> toggle(String key, bool on) async {
    final next = {...state};
    if (on) {
      next.add(key);
    } else {
      next.remove(key);
    }
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_kOverlayPref, next.toList());

    final controller = ref.read(mapControllerProvider);
    final def = overlayByKey(key);
    if (controller == null || def == null) return;
    if (on) {
      await _install(controller, def);
    } else {
      await _remove(controller, def);
    }
  }

  /// Reinstall every enabled overlay on the current style. Called after a style
  /// load, when the previous style's runtime sources are gone.
  Future<void> reinstall() async {
    final controller = ref.read(mapControllerProvider);
    if (controller == null) return;
    for (final key in state) {
      final def = overlayByKey(key);
      if (def != null) await _install(controller, def);
    }
  }

  Future<void> _install(MapLibreMapController c, OverlayDef def) async {
    final source = def.tileUrl;
    if (source == null) return;
    await _remove(c, def); // clear any stale copy (style reload or refresh)
    // ArcGIS export overlays use the {bbox-epsg-3857} token, which MapLibre
    // Native does not substitute; serve those through the on-device tile proxy.
    var tileUrl = source;
    if (source.contains('{bbox-epsg-3857}')) {
      tileUrl = await TileProxy.instance.register(def.key, source);
    }
    if (def.refresh != null) {
      final sep = tileUrl.contains('?') ? '&' : '?';
      tileUrl = '$tileUrl${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }
    try {
      await c.addSource(
        def.sourceId,
        RasterSourceProperties(tiles: [tileUrl], tileSize: 256),
      );
      // Below the first Cairn layer so overlays never hide trails, the route,
      // or fires (Fix Pass 1 X1.3.6/7).
      await c.addLayer(
        def.sourceId,
        def.layerId,
        RasterLayerProperties(rasterOpacity: def.opacity),
        belowLayerId: 'land-line',
        minzoom: def.minZoom.toDouble(),
        maxzoom: def.maxZoom.toDouble(),
      );
      _installedAt[def.key] = DateTime.now();
    } catch (_) {
      // A service that is down or a token the native map cannot substitute must
      // not crash the map. The row still shows as on; it retries on refresh.
    }
  }

  Future<void> _remove(MapLibreMapController c, OverlayDef def) async {
    try {
      await c.removeLayer(def.layerId);
    } catch (_) {}
    try {
      await c.removeSource(def.sourceId);
    } catch (_) {}
  }

  Future<void> _refreshDue() async {
    final controller = ref.read(mapControllerProvider);
    if (controller == null) return;
    final now = DateTime.now();
    for (final key in state) {
      final def = overlayByKey(key);
      if (def == null || def.refresh == null) continue;
      final last = _installedAt[key];
      if (last == null || now.difference(last) >= def.refresh!) {
        await _install(controller, def);
      }
    }
  }
}

final overlayControllerProvider =
    NotifierProvider<OverlayController, Set<String>>(OverlayController.new);
