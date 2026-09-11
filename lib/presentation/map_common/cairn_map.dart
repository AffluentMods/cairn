// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/theme/cairn_colors.dart';
import '../shell/shell_providers.dart';
import 'basemaps/basemap_registry.dart';
import 'camera_provider.dart';
import 'map_providers.dart';
import 'overlays/overlay_controller.dart';
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
    this.trackingMode = MyLocationTrackingMode.none,
    this.onCameraTrackingDismissed,
  });

  final int tabIndex;
  final void Function(MapLibreMapController controller)? onControllerReady;
  final Future<void> Function(MapLibreMapController controller)? onStyleLoaded;
  final Future<void> Function(MapLibreMapController controller)? onCameraIdle;
  final void Function(math.Point<double> point, LatLng coords)? onMapClick;
  final void Function(math.Point<double> point, LatLng coords)? onMapLongClick;
  final bool myLocationEnabled;

  /// Camera tracking of the location puck (Fix Pass 1 X2.6 follow mode). None
  /// on Explore; trackingCompass on Navigate while recording.
  final MyLocationTrackingMode trackingMode;

  /// Fires when a user gesture dismisses tracking, so Navigate can show a
  /// Recenter pill.
  final VoidCallback? onCameraTrackingDismissed;

  @override
  ConsumerState<CairnMap> createState() => _CairnMapState();
}

class _CairnMapState extends ConsumerState<CairnMap> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  bool _loadFailed = false;
  int _retryNonce = 0;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    _restartLoadTimer();
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _restartLoadTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_styleLoaded) setState(() => _loadFailed = true);
    });
  }

  void _onCreated(MapLibreMapController c) {
    _controller = c;
    ref.read(mapControllerProvider.notifier).state = c;
    widget.onControllerReady?.call(c);
  }

  Future<void> _onStyleLoaded() async {
    if (mounted) {
      setState(() {
        _styleLoaded = true;
        _loadFailed = false;
      });
      _loadTimer?.cancel();
    }
    final c = _controller;
    if (c == null) return;
    await addCairnIcons(c);
    await ref.read(overlayControllerProvider.notifier).reinstall();
    if (ref.read(tiltProvider)) {
      await c.animateCamera(CameraUpdate.tiltTo(60));
    }
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
    if (!active) return ColoredBox(color: context.cairn.background);
    // A base-map switch reloads the style: show the loading state again.
    ref.listen(basemapProvider, (_, __) {
      setState(() {
        _styleLoaded = false;
        _loadFailed = false;
      });
      _restartLoadTimer();
    });
    final base = ref.watch(basemapProvider);
    final cam = ref.read(cameraProvider);
    return Stack(
      children: [
        MapLibreMap(
          key: ValueKey('${base.key}#$_retryNonce'),
          styleString: base.assetPath,
          initialCameraPosition: cam,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationRenderMode: widget.myLocationEnabled
              ? MyLocationRenderMode.compass
              : MyLocationRenderMode.normal,
          myLocationTrackingMode: widget.trackingMode,
          compassEnabled: true,
          trackCameraPosition: true,
          onMapCreated: _onCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraIdle: _onCameraIdle,
          onCameraTrackingDismissed: widget.onCameraTrackingDismissed,
          onMapClick: widget.onMapClick,
          onMapLongClick: widget.onMapLongClick,
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
        ),
        if (!_styleLoaded)
          Positioned.fill(
            child: _MapLoading(
              failed: _loadFailed,
              onRetry: () {
                setState(() {
                  _loadFailed = false;
                  _styleLoaded = false;
                  _retryNonce++;
                });
                _restartLoadTimer();
              },
            ),
          ),
      ],
    );
  }
}

/// Covers the map until the style loads, so the first paint is the theme
/// background with a spinner rather than a black platform view (Fix Pass 1
/// X1.3.10). After 10 s with no style it offers Retry.
class _MapLoading extends StatelessWidget {
  const _MapLoading({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      color: scheme.onSurfaceVariant, size: 40),
                  const SizedBox(height: 12),
                  Text(l10n.mapLoadFailed,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: onRetry, child: Text(l10n.genericRetry)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(height: 12),
                  Text(l10n.mapLoading,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }
}
