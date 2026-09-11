// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/settings/settings_providers.dart';
import '../map_providers.dart';
import 'overlay_registry.dart';
import 'tile_proxy.dart';

const _kOverlayPref = 'map.overlays';

/// Tracks which raster overlays are on (persisted) and installs or removes them
/// on the live MapLibre controller. Overlays are reinstalled on every style
/// load (Addendum A5.3) and live ones (radar) refresh on their interval.
class OverlayController extends Notifier<Set<String>> {
  Timer? _refreshTimer;
  final Map<String, DateTime> _installedAt = {};

  @override
  Set<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getStringList(_kOverlayPref) ?? const [];
    _refreshTimer ??=
        Timer.periodic(const Duration(minutes: 1), (_) => _refreshDue());
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
    return saved.where((k) => overlayByKey(k) != null).toSet();
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
      await c.addLayer(
        def.sourceId,
        def.layerId,
        RasterLayerProperties(rasterOpacity: def.opacity),
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
