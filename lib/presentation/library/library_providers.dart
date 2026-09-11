// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
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
