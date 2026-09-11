// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/l10n/l10n_ext.dart';
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
    final route = ref.read(routeEditorProvider).polyline;
    final opts = {
      'lat': cam.target.latitude,
      'lon': cam.target.longitude,
      'zoom': cam.zoom,
      'bearing': cam.bearing,
      'route': route.length >= 2 ? lineToGeoJson(route) : null,
    };
    await _controller.runJavaScript('init(${jsonEncode(opts)})');
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
                    const Icon(Icons.cloud_off, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.nav3dNeedsConnection,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
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
        ],
      ),
    );
  }
}
