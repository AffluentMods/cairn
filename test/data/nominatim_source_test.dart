// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/sources/nominatim_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses jsonv2 results into places with a bounding box', () {
    final hits = parseNominatim([
      {
        'place_id': 1,
        'lat': '46.6082',
        'lon': '-121.6712',
        'category': 'place',
        'type': 'village',
        'name': 'Packwood',
        'display_name': 'Packwood, Lewis County, Washington, United States',
        'boundingbox': ['46.5882', '46.6282', '-121.6912', '-121.6512'],
      },
      {
        'place_id': 2,
        'lat': '46.4926',
        'lon': '-121.4622',
        'type': 'peak',
        'name': '',
        'display_name': 'Goat Rocks, Lewis County, Washington',
      },
      {'place_id': 3, 'lat': 'x', 'lon': '1'},
      'not a map',
    ]);
    expect(hits.length, 2);
    final pk = hits.first;
    expect(pk.name, 'Packwood');
    expect(pk.kind, 'village');
    expect(pk.lat, closeTo(46.6082, 1e-6));
    expect(pk.south, closeTo(46.5882, 1e-6));
    expect(pk.east, closeTo(-121.6512, 1e-6));
    expect(pk.isArea, isTrue);
    // No name: the first display_name segment; no bbox: a point.
    final goat = hits[1];
    expect(goat.name, 'Goat Rocks');
    expect(goat.isArea, isFalse);
    expect(goat.south, goat.lat);
  });
}
