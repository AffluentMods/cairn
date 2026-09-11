// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trail.freezed.dart';
part 'trail.g.dart';

/// A trail or path, the clean domain view of an OSM way enriched with USFS data
/// (spec Section 8, Phase 2). Pure Dart, no Flutter or Drift imports.
@freezed
class Trail with _$Trail {
  const factory Trail({
    required int id,
    required String highway,
    required double lengthM,
    @Default(false) bool informal,
    String? name,
    String? sacScale,
    String? trailVisibility,
    String? surface,
    String? usfsName,
    String? usfsNumber,

    /// Polyline as [lat, lon] pairs. Empty when only metadata is loaded.
    @Default(<List<double>>[]) List<List<double>> geometry,
  }) = _Trail;

  factory Trail.fromJson(Map<String, dynamic> json) => _$TrailFromJson(json);
}
