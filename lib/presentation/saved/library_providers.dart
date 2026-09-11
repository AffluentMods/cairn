// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/db/app_database.dart' show FavoriteTrail;
import '../../domain/models/offline_region.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/models/track.dart';

/// Bumped whenever the library changes (save, delete, import) so the lists
/// refetch.
final libraryRefreshProvider = StateProvider<int>((ref) => 0);

void bumpLibrary(WidgetRef ref) =>
    ref.read(libraryRefreshProvider.notifier).state++;

final savedRoutesProvider = FutureProvider<List<SavedRoute>>((ref) {
  ref.watch(libraryRefreshProvider);
  return ref.watch(routeRepositoryProvider).all();
});

final savedTracksProvider = FutureProvider<List<TrackSummary>>((ref) {
  ref.watch(libraryRefreshProvider);
  return ref.watch(trackRepositoryProvider).allTracks();
});

final offlineRegionsProvider = FutureProvider<List<OfflineRegionModel>>((ref) {
  ref.watch(libraryRefreshProvider);
  return ref.watch(offlineRepositoryProvider).all();
});

/// Saved trails (the Explore heart), newest first (Addendum A4.1 / A7).
final savedTrailListProvider = StreamProvider<List<FavoriteTrail>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchAll();
});

/// Just the saved trail ids, so a trail card can render its heart state live.
final savedTrailIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref
      .watch(favoritesRepositoryProvider)
      .watchAll()
      .map((rows) => rows.map((r) => r.trailId).toSet());
});
