// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/sync/sync_blob.dart';
import 'package:cairn/data/sync/sync_crypto.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';

AppDatabase memDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> addRoute(AppDatabase db, String id, DateTime updated) async {
  await db.into(db.routes).insert(
        RoutesCompanion.insert(
          id: id,
          name: 'Route $id',
          createdAt: updated,
          updatedAt: updated,
          geomJson: '[[46.0,-121.0],[46.1,-121.1]]',
          distanceM: 1000,
          gainM: 100,
          lossM: 50,
          maxElevM: 1500,
          minElevM: 1000,
        ),
      );
}

void main() {
  test('crypto: derive is deterministic, wrap/unwrap round-trips', () async {
    final c = SyncCrypto();
    final salt = c.newSalt();
    const params = Argon2Params();
    final k1 = await c.deriveMasterKey('correct horse', salt, params);
    final k2 = await c.deriveMasterKey('correct horse', salt, params);
    expect(k1, k2);
    final k3 = await c.deriveMasterKey('wrong', salt, params);
    expect(k3, isNot(k1));

    final dek = c.newDek();
    final wrapped = await c.wrapDek(dek, k1);
    final unwrapped = await c.unwrapDek(wrapped, k1);
    expect(unwrapped, dek);
    // Wrong master key fails to unwrap (GCM auth tag).
    expect(() => c.unwrapDek(wrapped, k3), throwsA(anything));
  });

  test('crypto: blob encrypt then decrypt round-trips', () async {
    final c = SyncCrypto();
    final dek = c.newDek();
    final plaintext = utf8.encode('{"hello":"world"}');
    final enc = await c.encryptBlob(plaintext, dek);
    final dec = await c.decryptBlob(enc, dek);
    expect(utf8.decode(dec), '{"hello":"world"}');
  });

  test('gatherAll then restoreAll copies routes to another device', () async {
    final a = memDb();
    final b = memDb();
    addTearDown(a.close);
    addTearDown(b.close);

    await addRoute(a, 'r1', DateTime(2026, 9, 10));
    final blob = await gatherAll(a);
    await restoreAll(b, blob);

    final onB = await b.select(b.routes).get();
    expect(onB.map((r) => r.id), ['r1']);
  });

  test('a tombstone propagates a deletion and does not resurrect', () async {
    final a = memDb();
    final b = memDb();
    addTearDown(a.close);
    addTearDown(b.close);

    // Both have r1. B deletes it (writes a tombstone).
    await addRoute(a, 'r1', DateTime(2026, 9, 10));
    await addRoute(b, 'r1', DateTime(2026, 9, 10));
    await b.into(b.tombstones).insert(
          TombstonesCompanion.insert(
            entityType: 'route',
            entityId: 'r1',
            deletedAt: DateTime(2026, 9, 11),
          ),
        );
    await (b.delete(b.routes)..where((t) => t.id.equals('r1'))).go();

    // A syncs in B's blob: r1 should be deleted on A and stay deleted.
    await restoreAll(a, await gatherAll(b));
    expect(await a.select(a.routes).get(), isEmpty);

    // A pushes back: B must not resurrect r1.
    await restoreAll(b, await gatherAll(a));
    expect(await b.select(b.routes).get(), isEmpty);
  });

  test('newer edit beats older tombstone', () async {
    final a = memDb();
    addTearDown(a.close);
    // Local edit newer than an incoming tombstone: the route survives.
    await addRoute(a, 'r1', DateTime(2026, 9, 20));
    final incoming = {
      'schema_version': 1,
      'routes': [],
      'tracks': [],
      'tombstones': [
        {
          'entityType': 'route',
          'entityId': 'r1',
          'deletedAt': DateTime(2026, 9, 10).millisecondsSinceEpoch,
        },
      ],
    };
    await restoreAll(a, incoming);
    expect((await a.select(a.routes).get()).map((r) => r.id), ['r1']);
  });
}
