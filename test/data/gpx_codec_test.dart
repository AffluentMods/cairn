// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/gpx/gpx_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export then re-parse preserves route geometry', () {
    final geometry = [
      [46.47, -121.46],
      [46.48, -121.45],
      [46.49, -121.44],
    ];
    final xml = exportRouteGpx(name: 'Goat Rocks', geometry: geometry);
    final parsed = parseGpx(xml);
    expect(parsed.tracks.length, 1);
    final pts = parsed.tracks.first.points;
    expect(pts.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(pts[i].lat, closeTo(geometry[i][0], 1e-6));
      expect(pts[i].lon, closeTo(geometry[i][1], 1e-6));
    }
  });

  test('track export carries timestamps', () {
    final t0 = DateTime.utc(2026, 9, 10, 14);
    final xml = exportTrackGpx(
      name: 'walk',
      points: [
        GpxPt(lat: 46.0, lon: -121.0, ele: 1200, time: t0),
        GpxPt(
          lat: 46.001,
          lon: -121.0,
          ele: 1210,
          time: t0.add(const Duration(minutes: 1)),
        ),
      ],
    );
    final parsed = parseGpx(xml);
    expect(parsed.tracks.first.points.first.time, t0);
    expect(parsed.tracks.first.points.first.ele, closeTo(1200, 1e-6));
  });

  test('malformed input throws FormatException, not a crash', () {
    expect(() => parseGpx('this is not gpx <<<'), throwsFormatException);
  });

  test('a rte becomes a route', () {
    const xml = '''
<?xml version="1.0"?>
<gpx version="1.1" creator="test" xmlns="http://www.topografix.com/GPX/1/1">
  <rte><name>R</name>
    <rtept lat="46.4" lon="-121.4"></rtept>
    <rtept lat="46.5" lon="-121.5"></rtept>
  </rte>
</gpx>''';
    final parsed = parseGpx(xml);
    expect(parsed.routes.length, 1);
    expect(parsed.routes.first.points.length, 2);
  });
}
