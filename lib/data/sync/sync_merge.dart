// SPDX-License-Identifier: GPL-3.0-or-later

/// A record that can be merged: an id, its last-modified time (ms since epoch),
/// and its serialized data.
class Mergeable {
  const Mergeable({
    required this.id,
    required this.lastModifiedMs,
    required this.data,
  });
  final String id;
  final int lastModifiedMs;
  final Map<String, dynamic> data;
}

/// The resolved result of merging one entity type.
class MergeOutcome {
  const MergeOutcome({
    required this.upserts,
    required this.deletes,
    required this.tombstones,
  });

  /// Winning records that should exist after the merge (id -> data).
  final List<Mergeable> upserts;

  /// Ids that should be removed locally (a tombstone won).
  final Set<String> deletes;

  /// Merged tombstones (id -> deletedAt ms), to persist and re-propagate.
  final Map<String, int> tombstones;
}

/// Merges local and incoming records under one universal rule: newest wins (spec
/// sync-tombstones design). Per id, the event with the newest timestamp wins,
/// comparing record lastModified against tombstone deletedAt. Tombstones union
/// keeping the max deletedAt.
MergeOutcome mergeEntities({
  required List<Mergeable> local,
  required List<Mergeable> incoming,
  required Map<String, int> localTombstones,
  required Map<String, int> incomingTombstones,
}) {
  // Union tombstones, keeping the newest deletedAt per id.
  final tombstones = <String, int>{...localTombstones};
  incomingTombstones.forEach((id, ms) {
    final existing = tombstones[id];
    if (existing == null || ms > existing) tombstones[id] = ms;
  });

  // Newest record per id across local and incoming.
  final byId = <String, Mergeable>{};
  void consider(Mergeable m) {
    final existing = byId[m.id];
    if (existing == null || m.lastModifiedMs > existing.lastModifiedMs) {
      byId[m.id] = m;
    }
  }

  for (final m in local) {
    consider(m);
  }
  for (final m in incoming) {
    consider(m);
  }

  final localIds = {for (final m in local) m.id};
  final upserts = <Mergeable>[];
  final deletes = <String>{};

  byId.forEach((id, record) {
    final deletedAt = tombstones[id];
    if (deletedAt != null && deletedAt > record.lastModifiedMs) {
      // Delete wins. Remove locally if present; never resurrect.
      if (localIds.contains(id)) deletes.add(id);
    } else {
      // Record lives (edit wins, or no tombstone).
      upserts.add(record);
    }
  });

  // Ids present only as tombstones with a local record already handled above.
  // A tombstone with no record anywhere still needs to delete a local row if it
  // somehow exists (defensive).
  tombstones.forEach((id, ms) {
    if (!byId.containsKey(id) && localIds.contains(id)) deletes.add(id);
  });

  return MergeOutcome(
    upserts: upserts,
    deletes: deletes,
    tombstones: tombstones,
  );
}
