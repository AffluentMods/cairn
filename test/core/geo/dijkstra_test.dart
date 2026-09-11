// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/geo/dijkstra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixture graph (undirected):
  //   1 -1- 2 -1- 3 -1- 4 -1- 5
  //   1 -5- 3            2 -10- 5
  final adjacency = <int, List<GraphEdge>>{
    1: [const GraphEdge(2, 1), const GraphEdge(3, 5)],
    2: [const GraphEdge(1, 1), const GraphEdge(3, 1), const GraphEdge(5, 10)],
    3: [const GraphEdge(2, 1), const GraphEdge(1, 5), const GraphEdge(4, 1)],
    4: [const GraphEdge(3, 1), const GraphEdge(5, 1)],
    5: [const GraphEdge(4, 1), const GraphEdge(2, 10)],
  };

  test('finds the known shortest path', () {
    expect(dijkstraPath(adjacency, 1, 5), [1, 2, 3, 4, 5]);
  });

  test('start equals goal', () {
    expect(dijkstraPath(adjacency, 3, 3), [3]);
  });

  test('unreachable goal returns null', () {
    expect(dijkstraPath(adjacency, 1, 99), isNull);
  });

  test('prefers the cheaper of two routes', () {
    // 1 to 3 directly is 5, via 2 is 2.
    expect(dijkstraPath(adjacency, 1, 3), [1, 2, 3]);
  });
}
