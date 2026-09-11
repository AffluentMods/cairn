// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/dio_client.dart';
import '../core/settings/settings_providers.dart';
import '../domain/repositories/conditions_repository.dart';
import '../domain/repositories/elevation_repository.dart';
import '../domain/repositories/offline_repository.dart';
import '../domain/repositories/poi_repository.dart';
import '../domain/repositories/route_repository.dart';
import '../domain/repositories/track_repository.dart';
import '../domain/repositories/trail_repository.dart';
import 'db/app_database.dart';
import 'gpx/gpx_importer.dart';
import 'repositories/conditions_repository_impl.dart';
import 'repositories/elevation_repository_impl.dart';
import 'repositories/offline_repository_impl.dart';
import 'repositories/poi_repository_impl.dart';
import 'repositories/route_repository_impl.dart';
import 'repositories/track_repository_impl.dart';
import 'repositories/trail_repository_impl.dart';
import 'sources/affluent_proxy_source.dart';
import 'sources/nifc_source.dart';
import 'sources/nws_source.dart';
import 'sources/open_meteo_source.dart';
import 'sources/overpass_source.dart';
import 'sources/terrain_tile_source.dart';
import 'sources/usfs_source.dart';

/// The app support directory (for the terrain tile cache). Overridden in main()
/// with the resolved directory.
final appSupportDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('appSupportDirProvider not overridden'),
);

/// The single Drift database instance for the app's lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The shared Dio client (User-Agent, timeouts, release-safe logging).
final dioProvider = Provider<Dio>((ref) {
  final dio = buildDioClient();
  ref.onDispose(dio.close);
  return dio;
});

final overpassSourceProvider = Provider<OverpassSource>(
  (ref) => OverpassSource(ref.watch(dioProvider)),
);

final usfsSourceProvider = Provider<UsfsSource>(
  (ref) => UsfsSource(ref.watch(dioProvider)),
);

final nifcSourceProvider = Provider<NifcSource>(
  (ref) => NifcSource(ref.watch(dioProvider)),
);

final nwsSourceProvider = Provider<NwsSource>(
  (ref) => NwsSource(ref.watch(dioProvider)),
);

final openMeteoSourceProvider = Provider<OpenMeteoSource>(
  (ref) => OpenMeteoSource(ref.watch(dioProvider)),
);

/// The Affluent Labs proxy client, or null when no proxy URL is configured.
final affluentProxySourceProvider = Provider<AffluentProxySource?>((ref) {
  final base = ref.watch(settingsProvider.select((s) => s.proxyBaseUrl));
  if (base.isEmpty) return null;
  return AffluentProxySource(ref.watch(dioProvider), base);
});

final conditionsRepositoryProvider = Provider<ConditionsRepository>(
  (ref) => ConditionsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    nifc: ref.watch(nifcSourceProvider),
    nws: ref.watch(nwsSourceProvider),
    openMeteo: ref.watch(openMeteoSourceProvider),
    usfs: ref.watch(usfsSourceProvider),
    proxy: ref.watch(affluentProxySourceProvider),
  ),
);

final trailRepositoryProvider = Provider<TrailRepository>(
  (ref) => TrailRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    overpass: ref.watch(overpassSourceProvider),
    usfs: ref.watch(usfsSourceProvider),
  ),
);

final poiRepositoryProvider = Provider<PoiRepository>(
  (ref) => PoiRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    overpass: ref.watch(overpassSourceProvider),
  ),
);

final terrainTileSourceProvider = Provider<TerrainTileSource>(
  (ref) => TerrainTileSource(
    ref.watch(dioProvider),
    ref.watch(appSupportDirProvider),
  ),
);

final elevationRepositoryProvider = Provider<ElevationRepository>(
  (ref) => ElevationRepositoryImpl(ref.watch(terrainTileSourceProvider)),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final offlineRepositoryProvider = Provider<OfflineRepository>(
  (ref) => OfflineRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    trails: ref.watch(trailRepositoryProvider),
    pois: ref.watch(poiRepositoryProvider),
    terrain: ref.watch(terrainTileSourceProvider),
  ),
);

final gpxImporterProvider = Provider<GpxImporter>(
  (ref) => GpxImporter(
    routes: ref.watch(routeRepositoryProvider),
    tracks: ref.watch(trackRepositoryProvider),
    elevation: ref.watch(elevationRepositoryProvider),
  ),
);
