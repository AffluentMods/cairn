// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/dio_client.dart';
import '../domain/repositories/poi_repository.dart';
import '../domain/repositories/trail_repository.dart';
import 'db/app_database.dart';
import 'repositories/poi_repository_impl.dart';
import 'repositories/trail_repository_impl.dart';
import 'sources/overpass_source.dart';
import 'sources/usfs_source.dart';

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
