// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../shell/shell_providers.dart';
import 'basemaps/basemap_registry.dart';
import 'camera_provider.dart';
import 'map_providers.dart';
import 'poi_icons.dart';

/// The shared MapLibre surface for the Explore and Navigate tabs. It builds a
/// [MapLibreMap] only while its own tab is the active shell branch, so at most
/// one GL surface lives at a time (Addendum A3). The camera is shared and
/// persisted through [cameraProvider], so remounting restores the same view.
class CairnMap extends ConsumerStatefulWidget {
  const CairnMap({
    super.key,
    required this.tabIndex,
    this.onControllerReady,
    this.onStyleLoaded,
    this.onCameraIdle,
    this.onMapClick,
    this.onMapLongClick,
    this.myLocationEnabled = false,
  });

  final int tabIndex;
  final void Function(MapLibreMapController controller)? onControllerReady;
  final Future<void> Function(MapLibreMapController controller)? onStyleLoaded;
  final Future<void> Function(MapLibreMapController controller)? onCameraIdle;
  final void Function(math.Point<double> point, LatLng coords)? onMapClick;
  final void Function(math.Point<double> point, LatLng coords)? onMapLongClick;
  final bool myLocationEnabled;

  @override
  ConsumerState<CairnMap> createState() => _CairnMapState();
}

class _CairnMapState extends ConsumerState<CairnMap> {
  MapLibreMapController? _controller;

  void _onCreated(MapLibreMapController c) {
    _controller = c;
    ref.read(mapControllerProvider.notifier).state = c;
    widget.onControllerReady?.call(c);
  }

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null) return;
    await addCairnIcons(c);
    await ref.read(viewportProvider.notifier).updateFrom(c);
    await widget.onStyleLoaded?.call(c);
  }

  Future<void> _onCameraIdle() async {
    final c = _controller;
    if (c == null) return;
    await ref.read(viewportProvider.notifier).updateFrom(c);
    await ref.read(cameraProvider.notifier).captureFromActiveController();
    await widget.onCameraIdle?.call(c);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(shellIndexProvider) == widget.tabIndex;
    if (!active) return const ColoredBox(color: Color(0xFF0E1412));
    final base = ref.watch(basemapProvider);
    final cam = ref.read(cameraProvider);
    return MapLibreMap(
      key: ValueKey(base.key),
      styleString: base.assetPath,
      initialCameraPosition: cam,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationRenderMode: widget.myLocationEnabled
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      compassEnabled: true,
      trackCameraPosition: true,
      onMapCreated: _onCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraIdle: _onCameraIdle,
      onMapClick: widget.onMapClick,
      onMapLongClick: widget.onMapLongClick,
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
