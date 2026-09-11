// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../data/gpx/gpx_codec.dart';
import '../../domain/usecases/compute_route_stats.dart';
import '../map/map_geojson.dart';
import '../map/map_providers.dart';
import '../map/map_style.dart';
import '../plan/widgets/elevation_profile.dart';
import '../shared/empty_state.dart';
import '../shared/stat_tile.dart';

enum DetailKind { route, track }

/// Detail for a saved route or a recorded track: the geometry on a map, the full
/// elevation profile, stats, and GPX export (spec Phase 4).
class TrackDetailScreen extends ConsumerStatefulWidget {
  const TrackDetailScreen({required this.id, required this.kind, super.key});

  final String id;
  final DetailKind kind;

  @override
  ConsumerState<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _DetailData {
  const _DetailData({
    required this.name,
    required this.geometry,
    required this.stats,
    this.gpx,
  });
  final String name;
  final List<List<double>> geometry;
  final RouteStats stats;
  final String? gpx;
}

class _TrackDetailScreenState extends ConsumerState<TrackDetailScreen> {
  MapLibreMapController? _controller;
  late final Future<_DetailData?> _future = _load();

  Future<_DetailData?> _load() async {
    final elevation = ref.read(elevationRepositoryProvider);
    if (widget.kind == DetailKind.route) {
      final route = await ref.read(routeRepositoryProvider).byId(widget.id);
      if (route == null) return null;
      final stats = await computeRouteStats(route.geometry, elevation);
      return _DetailData(
        name: route.name,
        geometry: route.geometry,
        stats: stats,
        gpx: exportRouteGpx(
          name: route.name,
          geometry: route.geometry,
          elevations: [for (final p in stats.profile) p.elevM],
        ),
      );
    } else {
      final track =
          await ref.read(trackRepositoryProvider).trackById(widget.id);
      if (track == null) return null;
      final points =
          await ref.read(trackRepositoryProvider).pointsFor(widget.id);
      final geometry = [
        for (final p in points) [p.lat, p.lon],
      ];
      final stats = await computeRouteStats(geometry, elevation);
      return _DetailData(
        name: track.name,
        geometry: geometry,
        stats: stats,
        gpx: exportTrackGpx(
          name: track.name,
          points: [
            for (final p in points)
              GpxPt(lat: p.lat, lon: p.lon, ele: p.elevM, time: p.t),
          ],
        ),
      );
    }
  }

  Future<void> _drawRoute(List<List<double>> geometry) async {
    final c = _controller;
    if (c == null || geometry.isEmpty) return;
    await c.setGeoJsonSource('cairn-route', lineToGeoJson(geometry));
    var minLat = geometry.first[0], maxLat = geometry.first[0];
    var minLon = geometry.first[1], maxLon = geometry.first[1];
    for (final p in geometry) {
      minLat = p[0] < minLat ? p[0] : minLat;
      maxLat = p[0] > maxLat ? p[0] : maxLat;
      minLon = p[1] < minLon ? p[1] : minLon;
      maxLon = p[1] > maxLon ? p[1] : maxLon;
    }
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        left: 30,
        right: 30,
        top: 60,
        bottom: 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final style = ref.watch(settingsProvider.select((s) => s.mapStyle));
    final prefs = ref.read(sharedPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabLibrary)),
      body: FutureBuilder<_DetailData?>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.connectionState == ConnectionState.done) {
              return EmptyState(
                icon: Icons.error_outline,
                title: l10n.libraryEmptyRoutes,
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: MapLibreMap(
                  styleString: style.assetPath,
                  initialCameraPosition: initialCamera(prefs),
                  compassEnabled: true,
                  onMapCreated: (c) => _controller = c,
                  onStyleLoadedCallback: () => _drawRoute(data.geometry),
                  attributionButtonPosition:
                      AttributionButtonPosition.bottomLeft,
                ),
              ),
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (data.gpx != null)
                            TextButton.icon(
                              onPressed: () => _export(data),
                              icon: const Icon(Icons.ios_share, size: 18),
                              label: Text(l10n.gpxExport),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: fmt.distance(data.stats.distanceM),
                              label: l10n.statDistance,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: fmt.elevationSigned(data.stats.gainM),
                              label: l10n.statGain,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: fmt.elevation(data.stats.maxElevM),
                              label: l10n.statHighPoint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevationProfile(profile: data.stats.profile),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _export(_DetailData data) async {
    final gpx = data.gpx;
    if (gpx == null) return;
    final safe = data.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final bytes = Uint8List.fromList(utf8.encode(gpx));
    await Share.shareXFiles([
      XFile.fromData(bytes, name: '$safe.gpx', mimeType: 'application/gpx+xml'),
    ]);
  }
}
