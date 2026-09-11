// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/dijkstra.dart';
import '../../core/geo/haversine.dart';

/// A cached way in a form the router can use: node ids aligned to coordinates,
/// plus a traversal penalty (spec Section 8, Phase 3).
class RoutableWay {
  const RoutableWay({
    required this.id,
    required this.nodeIds,
    required this.coords,
    required this.penalty,
  });

  final int id;
  final List<int> nodeIds; // aligned with coords
  final List<List<double>> coords; // [[lat, lon], ...]
  final double penalty; // multiplier; double.infinity means impassable
}

/// A waypoint snapped onto a way.
class SnappedPoint {
  const SnappedPoint({
    required this.wayId,
    required this.segmentIndex,
    required this.lat,
    required this.lon,
  });

  final int wayId;
  final int segmentIndex; // snapped point lies on coords[segmentIndex..+1]
  final double lat;
  final double lon;
}

/// The result of routing one leg between two snapped waypoints.
class RouteResult {
  const RouteResult({
    required this.polyline,
    required this.offTrail,
    required this.lengthM,
  });

  final List<List<double>> polyline; // [[lat, lon], ...]
  final bool offTrail; // true when no trail path exists (straight line)
  final double lengthM;
}

/// Traversal penalty for a way from its tags (spec Section 8, Phase 3): 1.4 for
/// informal paths, 3.0 for difficult alpine, impassable for private access.
double routePenalty({
  required bool informal,
  String? sacScale,
  String? access,
}) {
  if (access == 'private' || access == 'no') return double.infinity;
  var penalty = 1.0;
  if (informal) penalty *= 1.4;
  if (sacScale == 'difficult_alpine_hiking') penalty *= 3.0;
  return penalty;
}

const int _startVertex = -1;
const int _endVertex = -2;

/// Routes one leg between two snapped waypoints over the trail graph built from
/// [ways]. Falls back to a straight, off-trail line when no path exists. Never
/// silently draws a straight line without the flag.
RouteResult routeBetweenWaypoints(
  List<RoutableWay> ways,
  SnappedPoint a,
  SnappedPoint b,
) {
  final coordOf = <int, List<double>>{};
  final adjacency = <int, List<GraphEdge>>{};

  void addEdge(int from, int to, double weight) {
    (adjacency[from] ??= []).add(GraphEdge(to, weight));
  }

  for (final way in ways) {
    if (way.penalty.isInfinite) continue;
    for (var i = 0; i < way.nodeIds.length; i++) {
      coordOf.putIfAbsent(way.nodeIds[i], () => way.coords[i]);
    }
    for (var i = 0; i < way.nodeIds.length - 1; i++) {
      final u = way.nodeIds[i], v = way.nodeIds[i + 1];
      final w = haversineMeters(
            way.coords[i][0],
            way.coords[i][1],
            way.coords[i + 1][0],
            way.coords[i + 1][1],
          ) *
          way.penalty;
      addEdge(u, v, w);
      addEdge(v, u, w);
    }
  }

  final hostA = _wayById(ways, a.wayId);
  final hostB = _wayById(ways, b.wayId);
  if (hostA == null || hostB == null) {
    return _straightLeg(a, b);
  }

  _connectVirtual(_startVertex, a, hostA, coordOf, addEdge);
  _connectVirtual(_endVertex, b, hostB, coordOf, addEdge);

  // Same segment: allow the direct sub-segment so the leg does not detour to a
  // node and back.
  if (a.wayId == b.wayId && a.segmentIndex == b.segmentIndex) {
    final d = haversineMeters(a.lat, a.lon, b.lat, b.lon) * hostA.penalty;
    addEdge(_startVertex, _endVertex, d);
    addEdge(_endVertex, _startVertex, d);
  }

  coordOf[_startVertex] = [a.lat, a.lon];
  coordOf[_endVertex] = [b.lat, b.lon];

  final path = dijkstraPath(adjacency, _startVertex, _endVertex);
  if (path == null) {
    return _straightLeg(a, b);
  }

  final polyline = <List<double>>[];
  for (final node in path) {
    final c = coordOf[node];
    if (c != null) polyline.add(c);
  }
  return RouteResult(
    polyline: polyline,
    offTrail: false,
    lengthM: polylineLengthMeters(polyline),
  );
}

void _connectVirtual(
  int virtual,
  SnappedPoint p,
  RoutableWay host,
  Map<int, List<double>> coordOf,
  void Function(int, int, double) addEdge,
) {
  final k = p.segmentIndex.clamp(0, host.nodeIds.length - 2);
  final nodeA = host.nodeIds[k], nodeB = host.nodeIds[k + 1];
  final dA =
      haversineMeters(p.lat, p.lon, host.coords[k][0], host.coords[k][1]) *
          host.penalty;
  final dB = haversineMeters(
        p.lat,
        p.lon,
        host.coords[k + 1][0],
        host.coords[k + 1][1],
      ) *
      host.penalty;
  addEdge(virtual, nodeA, dA);
  addEdge(nodeA, virtual, dA);
  addEdge(virtual, nodeB, dB);
  addEdge(nodeB, virtual, dB);
}

RoutableWay? _wayById(List<RoutableWay> ways, int id) {
  for (final w in ways) {
    if (w.id == id) return w;
  }
  return null;
}

RouteResult _straightLeg(SnappedPoint a, SnappedPoint b) {
  final line = [
    [a.lat, a.lon],
    [b.lat, b.lon],
  ];
  return RouteResult(
    polyline: line,
    offTrail: true,
    lengthM: polylineLengthMeters(line),
  );
}
