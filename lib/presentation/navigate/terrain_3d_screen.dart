// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/l10n/l10n_ext.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/camera_provider.dart';
import '../map_common/map_geojson.dart';
import 'route_editor_provider.dart';

/// 3D terrain view (Addendum A5.2). MapLibre Native does not do 3D terrain on
/// Android/iOS yet, so this runs the bundled MapLibre GL JS in a WebView (system
/// WebView, no Play services). Online only: it shows a clear message with no
/// connection rather than a blank page.
class Terrain3dScreen extends ConsumerStatefulWidget {
  const Terrain3dScreen({super.key});

  @override
  ConsumerState<Terrain3dScreen> createState() => _Terrain3dScreenState();
}

class _Terrain3dScreenState extends ConsumerState<Terrain3dScreen> {
  late final WebViewController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1412))
      ..addJavaScriptChannel(
        'CairnBridge',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            if (!mounted) return;
            if (data['type'] == 'ready') setState(() => _ready = true);
            if (data['type'] == 'error' && !_ready) {
              setState(() => _error = true);
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // Only the bundled page (and the blank page used on dispose) may be
          // navigated to. Tile, sprite, and glyph fetches are XHR, not
          // navigations, so a redirecting map host cannot take over the
          // WebView (Addendum A5.2; security re-audit finding 18).
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('file:///android_asset/') ||
                url == 'about:blank') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) => _pushInit(),
          onWebResourceError: (_) {
            if (mounted && !_ready) setState(() => _error = true);
          },
        ),
      )
      ..loadFlutterAsset('assets/web/terrain3d.html');
  }

  Future<void> _pushInit() async {
    final cam = ref.read(cameraProvider);
    final base = ref.read(basemapProvider);
    final route = ref.read(routeEditorProvider).polyline;

    // Drape the active base map on the terrain (its sources already use absolute
    // HTTPS URLs and carry a terrain-dem source and route layers), rather than a
    // bare hillshade (Fix Pass 1 X3).
    final style = jsonDecode(await rootBundle.loadString(base.assetPath))
        as Map<String, dynamic>;

    List<List<double>>? bounds;
    List<double>? start;
    List<double>? end;
    if (route.length >= 2) {
      final sources = style['sources'];
      if (sources is Map && sources['cairn-route'] is Map) {
        (sources['cairn-route'] as Map)['data'] = lineToGeoJson(route);
      }
      var minLat = route.first[0], maxLat = route.first[0];
      var minLon = route.first[1], maxLon = route.first[1];
      for (final p in route) {
        if (p[0] < minLat) minLat = p[0];
        if (p[0] > maxLat) maxLat = p[0];
        if (p[1] < minLon) minLon = p[1];
        if (p[1] > maxLon) maxLon = p[1];
      }
      bounds = [
        [minLon, minLat],
        [maxLon, maxLat],
      ];
      start = [route.first[1], route.first[0]];
      end = [route.last[1], route.last[0]];
      // GeoJSON [lon, lat] for the fly-along path.
      _routeLngLat = [
        for (final p in route) [p[1], p[0]]
      ];
    }

    final opts = {
      'style': style,
      'lat': cam.target.latitude,
      'lon': cam.target.longitude,
      'zoom': cam.zoom,
      'bearing': cam.bearing,
      'bounds': bounds,
      'start': start,
      'end': end,
    };
    await _controller.runJavaScript('init(${jsonEncode(opts)})');
  }

  List<List<double>> _routeLngLat = const [];

  Future<void> _flyAlong() async {
    if (_routeLngLat.length < 2) return;
    await _controller.runJavaScript('flyAlong(${jsonEncode(_routeLngLat)})');
  }

  Future<void> _resetBearing() => _controller.runJavaScript('resetBearing()');

  void _retry() {
    setState(() {
      _error = false;
      _ready = false;
    });
    _controller.loadFlutterAsset('assets/web/terrain3d.html');
  }

  @override
  void dispose() {
    // Free the WebView GL context and tile cache on close (Fix Pass 1 X1.3.9).
    _controller
      ..clearCache()
      ..loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1412),
      body: Stack(
        children: [
          if (!_error)
            Positioned.fill(child: WebViewWidget(controller: _controller)),
          if (_error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.nav3dNeedsConnection,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: Text(l10n.genericRetry),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: const Color(0xE6152018),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: l10n.navClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (_ready && _routeLngLat.length >= 2)
            Positioned(
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Round3dButton(
                    icon: Icons.explore_outlined,
                    tooltip: l10n.nav3dResetNorth,
                    onPressed: _resetBearing,
                  ),
                  const SizedBox(height: 12),
                  _Round3dButton(
                    icon: Icons.slideshow,
                    tooltip: l10n.nav3dFlyAlong,
                    onPressed: _flyAlong,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Round3dButton extends StatelessWidget {
  const _Round3dButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6152018),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
