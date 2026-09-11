// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/track.dart';

/// Recorded tracks, persisted locally (spec Section 7, Phases 4 and 6).
abstract interface class TrackRepository {
  /// Save or replace a track and all its points in one transaction.
  Future<String> saveTrack(TrackSummary summary, List<TrackPointData> points);

  Future<List<TrackSummary>> allTracks();

  Future<TrackSummary?> trackById(String id);

  Future<List<TrackPointData>> pointsFor(String trackId);

  Future<void> deleteTrack(String id);

  // Live recording (Phase 6): create the row, append points, update the summary.
  Future<void> createTrack(TrackSummary summary);
  Future<void> appendPoint(String trackId, TrackPointData point);
  Future<void> updateSummary(TrackSummary summary);
}
