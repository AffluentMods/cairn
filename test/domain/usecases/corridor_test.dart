// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/offline_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 10 km trail heading north, one vertex every ~111 m.
  final route = [
    for (var i = 0; i <= 90; i++) [46.0 + i * 0.001, -121.0]
  ];

  test('corridor boxes chunk the route and pad by the buffer', () {
    final boxes = corridorBoxes(route, bufferM: 1500, chunkM: 2500);
    // 10 km in chunks that close once they pass 2.5 km (about 2.56 km at this
    // vertex spacing): three full chunks plus the tail.
    expect(boxes.length, 4);
    for (final b in boxes) {
      expect(b[0], lessThan(b[2]));
      expect(b[1], lessThan(b[3]));
      // Padding: 1.5 km is about 0.0135 deg of latitude.
      expect(b[2] - b[0], greaterThan(0.026));
      expect(b[3] - b[1], greaterThan(0.026));
    }
    // The first box starts south of the route start and the last ends north
    // of the route end.
    expect(boxes.first[0], lessThan(46.0));
    expect(boxes.last[2], greaterThan(46.09));
  });

  test('a corridor at z15 to z16 is far smaller than the whole box', () {
    final boxes = corridorBoxes(route);
    final corridor = corridorTileCount(boxes, minZoom: 15, maxZoom: 16);
    expect(corridor, greaterThan(50));
    expect(corridor, lessThan(2000));
    // Overlapping chunk boxes never double count a tile.
    final single = corridorTileCount([boxes.first], minZoom: 15, maxZoom: 16);
    final doubled =
        corridorTileCount([boxes.first, boxes.first], minZoom: 15, maxZoom: 16);
    expect(doubled, single);
  });

  test('an empty route has no boxes', () {
    expect(corridorBoxes(const []), isEmpty);
  });
}
