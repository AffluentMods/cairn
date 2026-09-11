// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/dio_client.dart';
import '../domain/repositories/elevation_repository.dart';
import '../domain/repositories/poi_repository.dart';
import '../domain/repositories/route_repository.dart';
import '../domain/repositories/trail_repository.dart';
import 'db/app_database.dart';
import 'repositories/elevation_repository_impl.dart';
import 'repositories/poi_repository_impl.dart';
import 'repositories/route_repository_impl.dart';
import 'repositories/trail_repository_impl.dart';
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
