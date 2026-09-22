// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import '../../core/worker/geo_worker.dart';
import '../../domain/models/forest_road.dart';

/// One page of a Motor Vehicle Use Map query: the segments and whether the
/// service cut the page short (fetch the next offset).
class MvumPage {
  const MvumPage({required this.roads, required this.exceeded});
  final List<ForestRoad> roads;
  final bool exceeded;
}

/// [parseMvum] on a worker isolate, from the raw response body. Top-level so
/// the closure captures only plain data (see GeoWorker).
Future<MvumPage> parseMvumAsync(String raw, {required bool trails}) =>
    GeoWorker.run(
      'mvum',
      () => parseMvum(jsonDecode(raw) as Map<String, dynamic>, trails: trails),
    );

/// The MVUM vehicle-class fields, in the order the card lists them, with the
/// key each becomes in [RoadAccess.vehicle].
const mvumVehicleFields = <String, String>{
  'passengervehicle': 'passengerVehicle',
  'highclearancevehicle': 'highClearance',
  'truck': 'truck',
  'motorhome': 'motorhome',
  'fourwd_gt50inches': 'fourWd',
  'atv': 'atv',
  'motorcycle': 'motorcycle',
  'otherwheeled_ohv': 'otherOhv',
};

/// Parses a GeoJSON page from the Forest Service MVUM roads (layer 1) or
/// motorized trails (layer 2) service into [ForestRoad]s. A MultiLineString
/// becomes one segment per part. Pure: no network, fully unit-testable.
MvumPage parseMvum(Map<String, dynamic> json, {required bool trails}) {
  final features =
      (json['features'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final prefix = trails ? 't' : 'r';
  final out = <ForestRoad>[];
  for (final f in features) {
    final props = (f['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final routeId = (props['id'] ?? '').toString().trim();
    if (routeId.isEmpty) continue;
    final geometry = (f['geometry'] as Map?)?.cast<String, dynamic>();
    if (geometry == null) continue;
    final parts = <List<List<double>>>[];
    final coords = geometry['coordinates'];
    if (geometry['type'] == 'LineString' && coords is List) {
      parts.add(_latLon(coords));
    } else if (geometry['type'] == 'MultiLineString' && coords is List) {
      for (final part in coords) {
        if (part is List) parts.add(_latLon(part));
      }
    }
    final access = <RoadAccess>[];
    for (final entry in mvumVehicleFields.entries) {
      final status = props[entry.key]?.toString().toLowerCase();
      if (status != 'open') continue;
      final dates = props['${entry.key}_datesopen']?.toString().trim();
      access.add(RoadAccess(
        vehicle: entry.value,
        dates: dates == null || dates.isEmpty || dates == '01/01-12/31'
            ? 'yearlong'
            : dates,
      ));
    }
    final seasonalField = props['seasonal']?.toString().toLowerCase();
    final symbolName = props['mvum_symbol_name']?.toString();
    final seasonal = seasonalField == 'seasonal' ||
        (seasonalField == null &&
            (symbolName?.toLowerCase().contains('seasonal') ?? false));
    final rawName = props['name']?.toString().trim();
    for (var i = 0; i < parts.length; i++) {
      final geom = parts[i];
      if (geom.length < 2) continue;
      out.add(ForestRoad(
        id: '$prefix$routeId${i == 0 ? '' : '#$i'}',
        routeId: routeId,
        number: forestRoadNumber(routeId),
        kind: trails ? 'trail' : 'road',
        symbol: int.tryParse(props['symbol']?.toString() ?? '') ?? 0,
        symbolName: symbolName,
        seasonal: seasonal,
        name: rawName == null || rawName.isEmpty ? null : titleCase(rawName),
        surface: props['surfacetype']?.toString(),
        maintLevel: props['operationalmaintlevel']?.toString(),
        access: access,
        lengthMi: (props['gis_miles'] as num?)?.toDouble(),
        geometry: geom,
      ));
    }
  }
  return MvumPage(
    roads: out,
    exceeded: json['exceededTransferLimit'] == true ||
        (json['properties'] is Map &&
            (json['properties'] as Map)['exceededTransferLimit'] == true),
  );
}

List<List<double>> _latLon(List<dynamic> coords) => [
      for (final c in coords)
        if (c is List && c.length >= 2)
          [(c[1] as num).toDouble(), (c[0] as num).toDouble()],
    ];

/// "JOHNSON CREEK SNO-PARK" to "Johnson Creek Sno-Park": the MVUM publishes
/// names in capitals. Short connectors stay lowercase inside a name.
String titleCase(String s) {
  const small = {'of', 'the', 'and', 'to', 'at', 'in', 'on'};
  final words = s.toLowerCase().split(RegExp(r'\s+'));
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.isEmpty) continue;
    if (i > 0 && small.contains(w)) {
      out.add(w);
      continue;
    }
    out.add(w.split('-').map(_capitalize).join('-'));
  }
  return out.join(' ');
}

String _capitalize(String w) =>
    w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}';
