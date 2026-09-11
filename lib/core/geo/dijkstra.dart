// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:collection/collection.dart';

/// A weighted directed edge in the routing graph.
class GraphEdge {
  const GraphEdge(this.to, this.weight);
  final int to;
  final double weight;
}

/// Dijkstra shortest path over an adjacency map keyed by vertex id (spec Section
/// 8, Phase 3). Returns the vertex id path from [start] to [goal] inclusive, or
/// null if [goal] is unreachable. Uses a binary heap so a few thousand vertices
/// stay fast.
List<int>? dijkstraPath(
  Map<int, List<GraphEdge>> adjacency,
  int start,
  int goal,
) {
  if (start == goal) return [start];

  final dist = <int, double>{start: 0};
  final prev = <int, int>{};
  final visited = <int>{};
  final queue = HeapPriorityQueue<_Entry>((a, b) => a.dist.compareTo(b.dist))
    ..add(_Entry(start, 0));

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final u = current.vertex;
    if (!visited.add(u)) continue;
    if (u == goal) break;

    for (final edge in adjacency[u] ?? const <GraphEdge>[]) {
      if (visited.contains(edge.to)) continue;
      final nd = current.dist + edge.weight;
      if (nd < (dist[edge.to] ?? double.infinity)) {
        dist[edge.to] = nd;
        prev[edge.to] = u;
        queue.add(_Entry(edge.to, nd));
      }
    }
  }

  if (!prev.containsKey(goal) && start != goal) return null;

  final path = <int>[goal];
  var node = goal;
  while (node != start) {
    final p = prev[node];
    if (p == null) return null; // unreachable
    path.add(p);
    node = p;
  }
  return path.reversed.toList();
}

class _Entry {
  _Entry(this.vertex, this.dist);
  final int vertex;
  final double dist;
}
