// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/select_route_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectRouteSection', () {
    test('keeps a short trail whole', () {
      final geom = [
        [46.0, -121.0],
        [46.0, -120.99],
        [46.0, -120.98],
      ];
      expect(selectRouteSection(geom), hasLength(3));
    });

    test('orients to start at the end nearest the user', () {
      final geom = [
        [46.0, -121.0],
        [46.0, -120.5],
      ];
      final r = selectRouteSection(geom, userLat: 46.0, userLon: -120.5);
      expect(r.first, [46.0, -120.5]); // reversed to start near the user
    });

    test('clips a long trail to the viewport plus margin', () {
      // ~29 mi east-west line, well over the 15 mi whole-trail cap.
      final geom = [
        for (var i = 0; i <= 100; i++) [46.0, -121.0 + i * 0.006],
      ];
      final vp = [46.0 - 0.001, -120.72, 46.0 + 0.001, -120.68];
      final r = selectRouteSection(geom, viewportBbox: vp);
      expect(r.length, lessThan(geom.length));
      expect(r.length, greaterThanOrEqualTo(2));
    });

    test('routeStartIsFar flags a distant trailhead', () {
      final geom = [
        [46.0, -121.0],
        [46.0, -120.99],
      ];
      expect(routeStartIsFar(geom, userLat: 46.0, userLon: -121.0), isFalse);
      expect(routeStartIsFar(geom, userLat: 46.1, userLon: -121.0), isTrue);
    });
  });
}
