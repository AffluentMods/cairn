// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/sync/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

Mergeable rec(String id, int ms) =>
    Mergeable(id: id, lastModifiedMs: ms, data: {'id': id, 'v': ms});

void main() {
  group('mergeEntities: newest wins', () {
    test('edit vs edit keeps the newer record', () {
      final out = mergeEntities(
        local: [rec('a', 100)],
        incoming: [rec('a', 200)],
        localTombstones: const {},
        incomingTombstones: const {},
      );
      expect(out.upserts.single.lastModifiedMs, 200);
      expect(out.deletes, isEmpty);
    });

    test('a newer delete removes the record and does not resurrect', () {
      final out = mergeEntities(
        local: [rec('a', 100)],
        incoming: const [],
        localTombstones: const {},
        incomingTombstones: const {'a': 150},
      );
      expect(out.deletes, {'a'});
      expect(out.upserts, isEmpty);
      expect(out.tombstones['a'], 150);
    });

    test('a newer edit beats an older delete', () {
      final out = mergeEntities(
        local: [rec('a', 300)],
        incoming: const [],
        localTombstones: const {},
        incomingTombstones: const {'a': 150},
      );
      expect(out.upserts.single.id, 'a');
      expect(out.deletes, isEmpty);
    });

    test('delete propagates from incoming even if local still has the record',
        () {
      // Device B deleted 'a'; device A still has an older copy.
      final out = mergeEntities(
        local: [rec('a', 100)],
        incoming: const [],
        localTombstones: const {},
        incomingTombstones: const {'a': 200},
      );
      expect(out.deletes, {'a'});
    });

    test('tombstones union keeps the newest deletedAt', () {
      final out = mergeEntities(
        local: const [],
        incoming: const [],
        localTombstones: const {'a': 100},
        incomingTombstones: const {'a': 250, 'b': 50},
      );
      expect(out.tombstones['a'], 250);
      expect(out.tombstones['b'], 50);
    });

    test('records from both sides survive when unrelated', () {
      final out = mergeEntities(
        local: [rec('a', 100)],
        incoming: [rec('b', 100)],
        localTombstones: const {},
        incomingTombstones: const {},
      );
      expect(out.upserts.map((m) => m.id).toSet(), {'a', 'b'});
    });
  });
}
