// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cairn_colors.dart';
import '../../data/data_providers.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/models/track.dart';
import '../shared/sparkline.dart';

/// Per-item elevation samples, kept for the session so a list scroll does not
/// re-read the DEM or the track points.
final _cache = <String, List<double>>{};

/// The elevation sparkline for a saved route row (spec Phase 4): the DEM along
/// up to 48 points of its geometry. Empty (and blank) when no DEM is cached.
class RouteSparkline extends ConsumerWidget {
  const RouteSparkline({required this.route, super.key});
  final SavedRoute route;

  Future<List<double>> _load(WidgetRef ref) async {
    final key = 'route:${route.id}:${route.updatedAt.millisecondsSinceEpoch}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final geometry = route.geometry;
    if (geometry.length < 2) return const [];
    final step = geometry.length <= 48 ? 1 : geometry.length / 47;
    final sample = <List<double>>[
      for (var i = 0; i < 48 && (i * step).round() < geometry.length; i++)
        geometry[(i * step).round()],
    ];
    if (sample.last != geometry.last) sample.add(geometry.last);
    try {
      final elevs =
          await ref.read(elevationRepositoryProvider).elevationsAlong(sample);
      return _cache[key] = elevs;
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<double>>(
      future: _load(ref),
      builder: (context, snap) {
        final values = snap.data ?? const <double>[];
        return Sparkline(values: values);
      },
    );
  }
}

/// The elevation sparkline for a recorded track row: DEM elevation where
/// known, else the smoothed GPS altitude, downsampled to 48 points.
class TrackSparkline extends ConsumerWidget {
  const TrackSparkline({required this.track, super.key});
  final TrackSummary track;

  Future<List<double>> _load(WidgetRef ref) async {
    final key = 'track:${track.id}:${track.endedAt?.millisecondsSinceEpoch}';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final points =
          await ref.read(trackRepositoryProvider).pointsFor(track.id);
      final elevs = <double>[
        for (final p in points)
          if (p.elevM != null) p.elevM!,
      ];
      return _cache[key] = downsampleForSparkline(elevs);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<double>>(
      future: _load(ref),
      builder: (context, snap) {
        final values = snap.data ?? const <double>[];
        // Tracks draw in the track color, as on the map.
        return Sparkline(values: values, color: context.cairn.track);
      },
    );
  }
}
