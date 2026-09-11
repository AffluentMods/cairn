// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/settings/settings_providers.dart';
import 'map_providers.dart';
import 'map_style.dart';
import 'widgets/layer_switcher_sheet.dart';
import 'widgets/location_fab.dart';

/// The Map tab: a full-screen MapLibre map with switchable styles, hillshade,
/// the user location puck, compass, and the layer switcher (spec Phase 1).
/// Flutter widgets sit OVER the map in a Stack; overlays (trails, fires, route)
/// are MapLibre layers fed by GeoJSON sources, not Flutter widgets.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _controller;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    ref.read(mapControllerProvider.notifier).state = controller;
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await ref.read(viewportProvider.notifier).updateFrom(controller);
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    if (controller == null) return;
    await ref.read(viewportProvider.notifier).updateFrom(controller);
    await persistCamera(ref.read(sharedPreferencesProvider), controller);
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final locationEnabled = ref.watch(locationEnabledProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: style.assetPath,
            initialCameraPosition: initialCamera(prefs),
            myLocationEnabled: locationEnabled,
            myLocationRenderMode: locationEnabled
                ? MyLocationRenderMode.compass
                : MyLocationRenderMode.normal,
            compassEnabled: true,
            trackCameraPosition: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraIdle: _onCameraIdle,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
          Positioned(
            top: topInset + 8,
            right: 12,
            child: const LayerSwitcherButton(),
          ),
          const Positioned(
            right: 16,
            bottom: 24,
            child: LocationFab(),
          ),
        ],
      ),
    );
  }
}
