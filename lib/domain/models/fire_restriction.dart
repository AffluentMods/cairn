// SPDX-License-Identifier: GPL-3.0-or-later

/// A fire restriction or burn ban for a land unit (spec Phase 8). Served by the
/// Affluent Labs proxy from a hand-maintained file, since no public API exists.
class FireRestriction {
  const FireRestriction({
    required this.name,
    required this.stage,
    required this.summary,
    this.source,
    this.since,
  });

  final String name;
  final int stage;
  final String summary;
  final String? source;
  final String? since;
}
