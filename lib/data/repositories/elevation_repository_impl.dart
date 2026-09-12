// SPDX-License-Identifier: GPL-3.0-or-later
import '../../domain/repositories/elevation_repository.dart';
import '../sources/terrain_tile_source.dart';

/// A remote elevation lookup for points with no terrain tile: parallel to the
/// input, null where unknown, or null as a whole on failure.
typedef RemoteElevations = Future<List<double?>?> Function(
  List<List<double>> latLon,
);

class ElevationRepositoryImpl implements ElevationRepository {
  ElevationRepositoryImpl(this._terrain, {RemoteElevations? remote})
      : _remote = remote;

  final TerrainTileSource _terrain;
  final RemoteElevations? _remote;

  static const _remoteBatch = 100;

  /// Elevations along [points]. Terrain tiles first (cached or fetched); the
  /// points still unknown are asked from the remote fallback (Open-Meteo, at
  /// most one batch of 100, spread along the line and interpolated between);
  /// small gaps are filled from their neighbors. Returns an empty list when
  /// nothing at all is known, so callers show "unknown" rather than a flat
  /// profile at sea level (spec audit gap 28).
  @override
  Future<List<double>> elevationsAlong(List<List<double>> points) async {
    if (points.isEmpty) return const [];
    final raw = await _terrain.elevations(points);
    final missing = <int>[
      for (var i = 0; i < raw.length; i++)
        if (raw[i] == null) i,
    ];
    if (missing.isNotEmpty && _remote != null) {
      await _fillFromRemote(points, raw, missing);
    }
    if (raw.every((e) => e == null)) return const [];
    return _fillGaps(raw);
  }

  Future<void> _fillFromRemote(
    List<List<double>> points,
    List<double?> raw,
    List<int> missing,
  ) async {
    // Up to 100 anchors spread evenly over the missing indices.
    final anchors = <int>[];
    if (missing.length <= _remoteBatch) {
      anchors.addAll(missing);
    } else {
      final step = (missing.length - 1) / (_remoteBatch - 1);
      for (var k = 0; k < _remoteBatch; k++) {
        anchors.add(missing[(k * step).round()]);
      }
    }
    final remote = _remote;
    if (remote == null) return;
    List<double?>? got;
    try {
      got = await remote([for (final i in anchors) points[i]]);
    } on Exception {
      got = null;
    }
    if (got == null) return;
    for (var k = 0; k < anchors.length; k++) {
      raw[anchors[k]] = got[k];
    }
    // Interpolate the missing indices between known anchors by index.
    for (final i in missing) {
      if (raw[i] != null) continue;
      var lo = i - 1;
      while (lo >= 0 && raw[lo] == null) {
        lo--;
      }
      var hi = i + 1;
      while (hi < raw.length && raw[hi] == null) {
        hi++;
      }
      if (lo >= 0 && hi < raw.length) {
        final t = (i - lo) / (hi - lo);
        raw[i] = raw[lo]! + (raw[hi]! - raw[lo]!) * t;
      }
    }
  }

  @override
  Future<double?> elevationAt(double lat, double lon) async {
    final local = await _terrain.elevationAt(lat, lon);
    if (local != null || _remote == null) return local;
    try {
      final got = await _remote([
        [lat, lon]
      ]);
      return got == null || got.isEmpty ? null : got.first;
    } on Exception {
      return null;
    }
  }

  /// Forward-fills nulls from the last known value and back-fills any leading
  /// nulls from the first known value.
  List<double> _fillGaps(List<double?> raw) {
    final out = List<double>.filled(raw.length, 0);
    double? last;
    for (var i = 0; i < raw.length; i++) {
      final v = raw[i];
      if (v != null) {
        out[i] = v;
        last = v;
      } else if (last != null) {
        out[i] = last;
      }
    }
    final firstValid = raw.indexWhere((e) => e != null);
    if (firstValid > 0) {
      final fill = raw[firstValid]!;
      for (var i = 0; i < firstValid; i++) {
        out[i] = fill;
      }
    }
    return out;
  }
}
