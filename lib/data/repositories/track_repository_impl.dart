// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../../domain/models/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../db/app_database.dart';

class TrackRepositoryImpl implements TrackRepository {
  TrackRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Future<String> saveTrack(
    TrackSummary summary,
    List<TrackPointData> points,
  ) async {
    await db.transaction(() async {
      await db
          .into(db.tracks)
          .insertOnConflictUpdate(_summaryCompanion(summary));
      await (db.delete(db.trackPoints)
            ..where((t) => t.trackId.equals(summary.id)))
          .go();
      await db.batch((b) {
        for (final p in points) {
          b.insert(db.trackPoints, _pointCompanion(summary.id, p));
        }
      });
    });
    return summary.id;
  }

  @override
  Future<void> createTrack(TrackSummary summary) =>
      db.into(db.tracks).insertOnConflictUpdate(_summaryCompanion(summary));

  @override
  Future<void> appendPoint(String trackId, TrackPointData point) =>
      db.into(db.trackPoints).insertOnConflictUpdate(
            _pointCompanion(trackId, point),
          );

  @override
  Future<void> updateSummary(TrackSummary summary) =>
      db.update(db.tracks).replace(_summaryRow(summary));

  @override
  Future<List<TrackSummary>> allTracks() async {
    final rows = await (db.select(db.tracks)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.map(_toSummary).toList();
  }

  @override
  Future<TrackSummary?> trackById(String id) async {
    final row = await (db.select(db.tracks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toSummary(row);
  }

  @override
  Future<List<TrackPointData>> pointsFor(String trackId) async {
    final rows = await (db.select(db.trackPoints)
          ..where((t) => t.trackId.equals(trackId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return [
      for (final r in rows)
        TrackPointData(
          seq: r.seq,
          t: r.t,
          lat: r.lat,
          lon: r.lon,
          gpsAltM: r.gpsAltM,
          demAltM: r.demAltM,
          accuracyM: r.accuracyM,
          speedMps: r.speedMps,
        ),
    ];
  }

  @override
  Future<void> deleteTrack(String id) async {
    await db.transaction(() async {
      await (db.delete(db.trackPoints)..where((t) => t.trackId.equals(id)))
          .go();
      await (db.delete(db.tracks)..where((t) => t.id.equals(id))).go();
    });
  }

  TracksCompanion _summaryCompanion(TrackSummary s) => TracksCompanion.insert(
        id: s.id,
        name: s.name,
        startedAt: s.startedAt,
        endedAt: Value(s.endedAt),
        distanceM: Value(s.distanceM),
        movingSeconds: Value(s.movingSeconds),
        totalSeconds: Value(s.totalSeconds),
        gainM: Value(s.gainM),
        lossM: Value(s.lossM),
        packWeightKg: Value(s.packWeightKg),
        calories: Value(s.calories),
        linkedRouteId: Value(s.linkedRouteId),
      );

  Track _summaryRow(TrackSummary s) => Track(
        id: s.id,
        name: s.name,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
        distanceM: s.distanceM,
        movingSeconds: s.movingSeconds,
        totalSeconds: s.totalSeconds,
        gainM: s.gainM,
        lossM: s.lossM,
        packWeightKg: s.packWeightKg,
        calories: s.calories,
        linkedRouteId: s.linkedRouteId,
      );

  TrackPointsCompanion _pointCompanion(String trackId, TrackPointData p) =>
      TrackPointsCompanion.insert(
        trackId: trackId,
        seq: p.seq,
        t: p.t,
        lat: p.lat,
        lon: p.lon,
        gpsAltM: Value(p.gpsAltM),
        demAltM: Value(p.demAltM),
        accuracyM: Value(p.accuracyM),
        speedMps: Value(p.speedMps),
      );

  TrackSummary _toSummary(Track row) => TrackSummary(
        id: row.id,
        name: row.name,
        startedAt: row.startedAt,
        endedAt: row.endedAt,
        distanceM: row.distanceM,
        movingSeconds: row.movingSeconds,
        totalSeconds: row.totalSeconds,
        gainM: row.gainM,
        lossM: row.lossM,
        packWeightKg: row.packWeightKg,
        calories: row.calories,
        linkedRouteId: row.linkedRouteId,
      );
}
