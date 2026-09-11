// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';

/// A trail way resolved from an Overpass response: geometry, tags, bbox, and the
/// endpoint node ids the routing graph needs (spec Section 8, Phase 2).
class ParsedWay {
  ParsedWay({
    required this.id,
    required this.highway,
    required this.tags,
    required this.geometry,
    required this.nodeIds,
    required this.lengthM,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });

  final int id;
  final String highway;
  final Map<String, String> tags;
  final List<List<double>> geometry; // [[lat, lon], ...]
  final List<int> nodeIds;
  final double lengthM;
  final double minLat, minLon, maxLat, maxLon;

  String? get name => tags['name'];
  String? get sacScale => tags['sac_scale'];
  String? get trailVisibility => tags['trail_visibility'];
  String? get surface => tags['surface'];
  bool get informal =>
      tags['informal'] == 'yes' || tags['trail_visibility'] == 'no';
  int get firstNodeId => nodeIds.first;
  int get lastNodeId => nodeIds.last;
}

/// A node shared by two or more ways: a vertex in the routing graph.
class ParsedNode {
  ParsedNode(this.id, this.lat, this.lon);
  final int id;
  final double lat;
  final double lon;
}

class ParsedRelation {
  ParsedRelation({
    required this.id,
    required this.tags,
    required this.memberWayIds,
  });
  final int id;
  final Map<String, String> tags;
  final List<int> memberWayIds;
  String? get name => tags['name'];
  String? get network => tags['network'];
}

class ParsedPoi {
  ParsedPoi({
    required this.id,
    required this.kind,
    required this.lat,
    required this.lon,
    required this.tags,
  });
  final String id; // "n123" or "w456"
  final String kind;
  final double lat;
  final double lon;
  final Map<String, String> tags;
  String? get name => tags['name'];
}

class OverpassWays {
  OverpassWays({
    required this.ways,
    required this.graphNodes,
    required this.relations,
  });
  final List<ParsedWay> ways;
  final List<ParsedNode> graphNodes;
  final List<ParsedRelation> relations;
}

Map<String, String> _tags(Map<String, dynamic> el) {
  final t = el['tags'];
  if (t is Map) {
    return t.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
  return const {};
}

/// Parses a raw Overpass JSON map into trail ways, the graph nodes shared by two
/// or more ways, and route relations. Pure: no network, fully unit-testable.
OverpassWays parseOverpassWays(Map<String, dynamic> json) {
  final elements = (json['elements'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];

  final nodeCoords = <int, List<double>>{};
  for (final el in elements) {
    if (el['type'] == 'node') {
      final id = (el['id'] as num).toInt();
      final lat = (el['lat'] as num?)?.toDouble();
      final lon = (el['lon'] as num?)?.toDouble();
      if (lat != null && lon != null) nodeCoords[id] = [lat, lon];
    }
  }

  final ways = <ParsedWay>[];
  final nodeUseCount = <int, int>{};

  for (final el in elements) {
    if (el['type'] != 'way') continue;
    final tags = _tags(el);
    final highway = tags['highway'];
    if (highway == null) continue; // skeleton ways carry no tags; skip.
    final nodeIds =
        (el['nodes'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            const <int>[];
    final geometry = <List<double>>[];
    for (final nid in nodeIds) {
      final c = nodeCoords[nid];
      if (c != null) geometry.add(c);
    }
    if (geometry.length < 2) continue;

    for (final nid in nodeIds) {
      nodeUseCount[nid] = (nodeUseCount[nid] ?? 0) + 1;
    }

    var minLat = geometry.first[0], maxLat = geometry.first[0];
    var minLon = geometry.first[1], maxLon = geometry.first[1];
    for (final p in geometry) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLon) minLon = p[1];
      if (p[1] > maxLon) maxLon = p[1];
    }

    ways.add(
      ParsedWay(
        id: (el['id'] as num).toInt(),
        highway: highway,
        tags: tags,
        geometry: geometry,
        nodeIds: nodeIds,
        lengthM: polylineLengthMeters(geometry),
        minLat: minLat,
        minLon: minLon,
        maxLat: maxLat,
        maxLon: maxLon,
      ),
    );
  }

  final graphNodes = <ParsedNode>[];
  nodeUseCount.forEach((id, count) {
    final c = nodeCoords[id];
    if (count >= 2 && c != null) {
      graphNodes.add(ParsedNode(id, c[0], c[1]));
    }
  });

  final relations = <ParsedRelation>[];
  for (final el in elements) {
    if (el['type'] != 'relation') continue;
    final members = (el['members'] as List?) ?? const [];
    final wayIds = <int>[];
    for (final m in members) {
      if (m is Map && m['type'] == 'way' && m['ref'] != null) {
        wayIds.add((m['ref'] as num).toInt());
      }
    }
    relations.add(
      ParsedRelation(
        id: (el['id'] as num).toInt(),
        tags: _tags(el),
        memberWayIds: wayIds,
      ),
    );
  }

  return OverpassWays(ways: ways, graphNodes: graphNodes, relations: relations);
}

const _poiKindByTag = <String, Map<String, String>>{
  'natural': {
    'spring': 'spring',
    'water': 'water',
    'peak': 'peak',
    'saddle': 'saddle',
  },
  'tourism': {
    'camp_site': 'camp_site',
    'wilderness_hut': 'hut',
    'viewpoint': 'viewpoint',
  },
  'amenity': {
    'toilets': 'toilets',
    'drinking_water': 'drinking_water',
    'parking': 'parking',
    'shelter': 'shelter',
  },
  'highway': {'trailhead': 'trailhead'},
  'waterway': {'stream': 'stream', 'river': 'river'},
};

String? _poiKind(Map<String, String> tags) {
  for (final entry in _poiKindByTag.entries) {
    final value = tags[entry.key];
    if (value != null && entry.value.containsKey(value)) {
      return entry.value[value];
    }
  }
  return null;
}

/// Parses the POI query response. Nodes become points; area/way features use
/// their first vertex as an anchor (good enough for labels and "near route").
List<ParsedPoi> parseOverpassPois(Map<String, dynamic> json) {
  final elements = (json['elements'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];

  final nodeCoords = <int, List<double>>{};
  for (final el in elements) {
    if (el['type'] == 'node') {
      final lat = (el['lat'] as num?)?.toDouble();
      final lon = (el['lon'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        nodeCoords[(el['id'] as num).toInt()] = [lat, lon];
      }
    }
  }

  final pois = <ParsedPoi>[];
  for (final el in elements) {
    final tags = _tags(el);
    if (tags.isEmpty) continue;
    final kind = _poiKind(tags);
    if (kind == null) continue;

    double? lat;
    double? lon;
    String idPrefix;
    if (el['type'] == 'node') {
      idPrefix = 'n';
      lat = (el['lat'] as num?)?.toDouble();
      lon = (el['lon'] as num?)?.toDouble();
    } else if (el['type'] == 'way') {
      idPrefix = 'w';
      final nodeIds =
          (el['nodes'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const <int>[];
      for (final nid in nodeIds) {
        final c = nodeCoords[nid];
        if (c != null) {
          lat = c[0];
          lon = c[1];
          break;
        }
      }
    } else {
      continue;
    }
    if (lat == null || lon == null) continue;

    pois.add(
      ParsedPoi(
        id: '$idPrefix${(el['id'] as num).toInt()}',
        kind: kind,
        lat: lat,
        lon: lon,
        tags: tags,
      ),
    );
  }
  return pois;
}
