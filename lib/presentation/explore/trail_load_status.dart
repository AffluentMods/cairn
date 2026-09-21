// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where Explore's trail loading stands for the current view, so the map can
/// show a progress pill and the "Trails in view" list can say why it is empty.
enum TrailLoadPhase {
  /// Nothing in flight: the view is cached (or the last pass finished).
  idle,

  /// Overpass cells are loading; [TrailLoadStatus.done] of
  /// [TrailLoadStatus.total] have landed.
  loading,

  /// The view spans more cells than one refresh may fetch; only cached trails
  /// draw until the user zooms in.
  tooWide,
}

class TrailLoadStatus {
  const TrailLoadStatus._(this.phase, this.done, this.total);

  static const idle = TrailLoadStatus._(TrailLoadPhase.idle, 0, 0);
  static const tooWide = TrailLoadStatus._(TrailLoadPhase.tooWide, 0, 0);

  const TrailLoadStatus.loading(int done, int total)
      : this._(TrailLoadPhase.loading, done, total);

  final TrailLoadPhase phase;
  final int done;
  final int total;

  bool get isLoading => phase == TrailLoadPhase.loading;

  @override
  bool operator ==(Object other) =>
      other is TrailLoadStatus &&
      other.phase == phase &&
      other.done == done &&
      other.total == total;

  @override
  int get hashCode => Object.hash(phase, done, total);
}

final trailLoadStatusProvider =
    StateProvider<TrailLoadStatus>((ref) => TrailLoadStatus.idle);
