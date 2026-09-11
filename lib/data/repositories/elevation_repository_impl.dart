// SPDX-License-Identifier: GPL-3.0-or-later
import '../../domain/repositories/elevation_repository.dart';
import '../sources/terrain_tile_source.dart';

class ElevationRepositoryImpl implements ElevationRepository {
  ElevationRepositoryImpl(this._terrain);

  final TerrainTileSource _terrain;

  @override
  Future<List<double>> elevationsAlong(List<List<double>> points) async {
    if (points.isEmpty) return const [];
    final raw = await _terrain.elevations(points);
    return _fillGaps(raw);
  }

  @override
  Future<double?> elevationAt(double lat, double lon) =>
      _terrain.elevationAt(lat, lon);

  /// Forward-fills nulls from the last known value, back-fills any leading nulls
  /// from the first known value. All-null (nothing cached) becomes zeros so the
  /// caller can still render a flat profile rather than crash.
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
    // Back-fill leading nulls.
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
