// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Saved trails, backed by the [FavoriteTrails] table (Addendum A4.1 / A7). The
/// trail id (`r<relationId>` or `w<firstWayId>`) is the stable key.
class FavoritesRepository {
  FavoritesRepository(this._db);

  final AppDatabase _db;

  Future<List<FavoriteTrail>> all() => (_db.select(_db.favoriteTrails)
        ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
      .get();

  Stream<List<FavoriteTrail>> watchAll() => (_db.select(_db.favoriteTrails)
        ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
      .watch();

  Future<bool> isSaved(String trailId) async {
    final row = await (_db.select(_db.favoriteTrails)
          ..where((t) => t.trailId.equals(trailId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> save({
    required String trailId,
    required String name,
    required double centerLat,
    required double centerLon,
    double? lengthM,
  }) {
    return _db.into(_db.favoriteTrails).insertOnConflictUpdate(
          FavoriteTrailsCompanion.insert(
            trailId: trailId,
            name: name,
            centerLat: centerLat,
            centerLon: centerLon,
            lengthM: Value(lengthM),
            savedAt: DateTime.now(),
          ),
        );
  }

  Future<void> remove(String trailId) =>
      (_db.delete(_db.favoriteTrails)..where((t) => t.trailId.equals(trailId)))
          .go();

  /// Save if not saved, remove if it is. Returns the new saved state.
  Future<bool> toggle({
    required String trailId,
    required String name,
    required double centerLat,
    required double centerLon,
    double? lengthM,
  }) async {
    if (await isSaved(trailId)) {
      await remove(trailId);
      return false;
    }
    await save(
      trailId: trailId,
      name: name,
      centerLat: centerLat,
      centerLon: centerLon,
      lengthM: lengthM,
    );
    return true;
  }
}
