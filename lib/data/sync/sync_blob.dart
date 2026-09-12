// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'sync_merge.dart';

/// The plaintext sync blob schema version. Bumping it forces older clients to
/// re-enroll rather than silently strip data they do not understand.
const int kSyncBlobSchema = 1;

/// Tombstones older than this are pruned to bound the blob size (spec sync
/// design). A device offline longer than this may resurrect one item once.
const _tombstoneRetention = Duration(days: 365);

int _ms(DateTime t) => t.millisecondsSinceEpoch;
DateTime _dt(Object? ms) =>
    DateTime.fromMillisecondsSinceEpoch((ms as num).toInt());

/// Serializes all synced data (routes, tracks with points, tombstones) into a
/// plaintext blob map. This is what gets encrypted before upload.
Future<Map<String, dynamic>> gatherAll(AppDatabase db) async {
  final routes = await db.select(db.routes).get();
  final routeWps = await db.select(db.routeWaypoints).get();
  final tracks = await db.select(db.tracks).get();
  final trackPts = await db.select(db.trackPoints).get();
  final tombstones = await db.select(db.tombstones).get();

  final wpsByRoute = <String, List<RouteWaypoint>>{};
  for (final w in routeWps) {
    (wpsByRoute[w.routeId] ??= []).add(w);
  }
  final ptsByTrack = <String, List<TrackPoint>>{};
  for (final p in trackPts) {
    (ptsByTrack[p.trackId] ??= []).add(p);
  }

  return {
    'schema_version': kSyncBlobSchema,
    'routes': [
      for (final r in routes)
        {
          'id': r.id,
          'name': r.name,
          'createdAt': _ms(r.createdAt),
          'updatedAt': _ms(r.updatedAt),
          'geomJson': r.geomJson,
          'distanceM': r.distanceM,
          'gainM': r.gainM,
          'lossM': r.lossM,
          'maxElevM': r.maxElevM,
          'minElevM': r.minElevM,
          'notes': r.notes,
          'waypoints': [
            for (final w in ([
              ...?wpsByRoute[r.id]
            ]..sort((a, b) => a.ordinal.compareTo(b.ordinal))))
              {
                'ordinal': w.ordinal,
                'lat': w.lat,
                'lon': w.lon,
                'label': w.label
              },
          ],
        },
    ],
    'tracks': [
      for (final t in tracks)
        {
          'id': t.id,
          'name': t.name,
          'startedAt': _ms(t.startedAt),
          'endedAt': t.endedAt == null ? null : _ms(t.endedAt!),
          'distanceM': t.distanceM,
          'movingSeconds': t.movingSeconds,
          'totalSeconds': t.totalSeconds,
          'gainM': t.gainM,
          'lossM': t.lossM,
          'packWeightKg': t.packWeightKg,
          'calories': t.calories,
          'linkedRouteId': t.linkedRouteId,
          'lastModified': _ms(t.lastModified),
          'batteryStartPct': t.batteryStartPct,
          'batteryEndPct': t.batteryEndPct,
          'points': [
            for (final p in ([
              ...?ptsByTrack[t.id]
            ]..sort((a, b) => a.seq.compareTo(b.seq))))
              {
                'seq': p.seq,
                't': _ms(p.t),
                'lat': p.lat,
                'lon': p.lon,
                'gpsAltM': p.gpsAltM,
                'demAltM': p.demAltM,
                'accuracyM': p.accuracyM,
                'speedMps': p.speedMps,
              },
          ],
        },
    ],
    'tombstones': [
      for (final t in tombstones)
        {
          'entityType': t.entityType,
          'entityId': t.entityId,
          'deletedAt': _ms(t.deletedAt),
        },
    ],
  };
}

/// Merges an incoming blob into the local database (newest wins + tombstones),
/// preserving incoming timestamps so the merge stays correct across devices.
Future<void> restoreAll(AppDatabase db, Map<String, dynamic> blob) async {
  final incomingRoutes = (blob['routes'] as List?) ?? const [];
  final incomingTracks = (blob['tracks'] as List?) ?? const [];
  final incomingTombs = (blob['tombstones'] as List?) ?? const [];

  final incTombByType = <String, Map<String, int>>{'route': {}, 'track': {}};
  for (final t in incomingTombs.cast<Map<String, dynamic>>()) {
    final type = t['entityType'] as String;
    (incTombByType[type] ??= {})[t['entityId'] as String] =
        (t['deletedAt'] as num).toInt();
  }

  final local = await gatherAll(db);
  final localRouteTombs = <String, int>{};
  final localTrackTombs = <String, int>{};
  for (final t in (local['tombstones'] as List).cast<Map<String, dynamic>>()) {
    if (t['entityType'] == 'route') {
      localRouteTombs[t['entityId'] as String] =
          (t['deletedAt'] as num).toInt();
    } else {
      localTrackTombs[t['entityId'] as String] =
          (t['deletedAt'] as num).toInt();
    }
  }

  Mergeable toMergeable(Map<String, dynamic> m, String tsField) => Mergeable(
      id: m['id'] as String,
      lastModifiedMs: (m[tsField] as num).toInt(),
      data: m);

  final routeOutcome = mergeEntities(
    local: [
      for (final r in (local['routes'] as List).cast<Map<String, dynamic>>())
        toMergeable(r, 'updatedAt'),
    ],
    incoming: [
      for (final r in incomingRoutes.cast<Map<String, dynamic>>())
        toMergeable(r, 'updatedAt'),
    ],
    localTombstones: localRouteTombs,
    incomingTombstones: incTombByType['route']!,
  );

  final trackOutcome = mergeEntities(
    local: [
      for (final t in (local['tracks'] as List).cast<Map<String, dynamic>>())
        toMergeable(t, 'lastModified'),
    ],
    incoming: [
      for (final t in incomingTracks.cast<Map<String, dynamic>>())
        toMergeable(t, 'lastModified'),
    ],
    localTombstones: localTrackTombs,
    incomingTombstones: incTombByType['track']!,
  );

  await db.transaction(() async {
    // Apply route upserts and deletes (preserving incoming timestamps).
    for (final m in routeOutcome.upserts) {
      await _writeRoute(db, m.data);
    }
    for (final id in routeOutcome.deletes) {
      await (db.delete(db.routeWaypoints)..where((t) => t.routeId.equals(id)))
          .go();
      await (db.delete(db.routes)..where((t) => t.id.equals(id))).go();
    }
    for (final m in trackOutcome.upserts) {
      await _writeTrack(db, m.data);
    }
    for (final id in trackOutcome.deletes) {
      await (db.delete(db.trackPoints)..where((t) => t.trackId.equals(id)))
          .go();
      await (db.delete(db.tracks)..where((t) => t.id.equals(id))).go();
    }

    // Persist merged tombstones (pruning old ones).
    final cutoff =
        DateTime.now().subtract(_tombstoneRetention).millisecondsSinceEpoch;
    await db.delete(db.tombstones).go();
    Future<void> writeTombs(String type, Map<String, int> tombs) async {
      for (final e in tombs.entries) {
        if (e.value < cutoff) continue;
        await db.into(db.tombstones).insert(
              TombstonesCompanion.insert(
                entityType: type,
                entityId: e.key,
                deletedAt: _dt(e.value),
              ),
            );
      }
    }

    await writeTombs('route', routeOutcome.tombstones);
    await writeTombs('track', trackOutcome.tombstones);
  });
}

Future<void> _writeRoute(AppDatabase db, Map<String, dynamic> r) async {
  final id = r['id'] as String;
  await db.into(db.routes).insertOnConflictUpdate(
        RoutesCompanion.insert(
          id: id,
          name: r['name'] as String,
          createdAt: _dt(r['createdAt']),
          updatedAt: _dt(r['updatedAt']),
          geomJson: r['geomJson'] as String,
          distanceM: (r['distanceM'] as num).toDouble(),
          gainM: (r['gainM'] as num).toDouble(),
          lossM: (r['lossM'] as num).toDouble(),
          maxElevM: (r['maxElevM'] as num).toDouble(),
          minElevM: (r['minElevM'] as num).toDouble(),
          notes: Value(r['notes'] as String?),
        ),
      );
  await (db.delete(db.routeWaypoints)..where((t) => t.routeId.equals(id))).go();
  for (final w in (r['waypoints'] as List).cast<Map<String, dynamic>>()) {
    await db.into(db.routeWaypoints).insert(
          RouteWaypointsCompanion.insert(
            routeId: id,
            ordinal: (w['ordinal'] as num).toInt(),
            lat: (w['lat'] as num).toDouble(),
            lon: (w['lon'] as num).toDouble(),
            label: Value(w['label'] as String?),
          ),
        );
  }
}

Future<void> _writeTrack(AppDatabase db, Map<String, dynamic> t) async {
  final id = t['id'] as String;
  await db.into(db.tracks).insertOnConflictUpdate(
        TracksCompanion.insert(
          id: id,
          name: t['name'] as String,
          startedAt: _dt(t['startedAt']),
          endedAt: Value(t['endedAt'] == null ? null : _dt(t['endedAt'])),
          distanceM: Value((t['distanceM'] as num).toDouble()),
          movingSeconds: Value((t['movingSeconds'] as num).toInt()),
          totalSeconds: Value((t['totalSeconds'] as num).toInt()),
          gainM: Value((t['gainM'] as num).toDouble()),
          lossM: Value((t['lossM'] as num).toDouble()),
          packWeightKg: Value((t['packWeightKg'] as num?)?.toDouble()),
          calories: Value((t['calories'] as num?)?.toDouble()),
          linkedRouteId: Value(t['linkedRouteId'] as String?),
          lastModified: Value(_dt(t['lastModified'])),
          batteryStartPct: Value((t['batteryStartPct'] as num?)?.toInt()),
          batteryEndPct: Value((t['batteryEndPct'] as num?)?.toInt()),
        ),
      );
  await (db.delete(db.trackPoints)..where((tp) => tp.trackId.equals(id))).go();
  for (final p in (t['points'] as List).cast<Map<String, dynamic>>()) {
    await db.into(db.trackPoints).insert(
          TrackPointsCompanion.insert(
            trackId: id,
            seq: (p['seq'] as num).toInt(),
            t: _dt(p['t']),
            lat: (p['lat'] as num).toDouble(),
            lon: (p['lon'] as num).toDouble(),
            gpsAltM: Value((p['gpsAltM'] as num?)?.toDouble()),
            demAltM: Value((p['demAltM'] as num?)?.toDouble()),
            accuracyM: Value((p['accuracyM'] as num?)?.toDouble()),
            speedMps: Value((p['speedMps'] as num?)?.toDouble()),
          ),
        );
  }
}
