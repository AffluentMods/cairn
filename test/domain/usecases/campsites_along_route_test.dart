// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/campsites_along_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 1 km line running north.
  final route = [
    for (var i = 0; i <= 10; i++) [46.40 + i * 0.0009, -121.40],
  ];

  test('keeps camps within 300 m, drops the rest, orders along the route', () {
    final camps = campsitesAlongRoute(route, [
      const CampCandidate(
          lat: 46.4072, lon: -121.4010, kind: 'camp_site', name: 'Far camp'),
      const CampCandidate(
          lat: 46.4018, lon: -121.4002, kind: 'hut', name: 'Near hut'),
      // 0.01 degrees of longitude at 46 N is about 770 m: too far.
      const CampCandidate(lat: 46.405, lon: -121.41, kind: 'camp_site'),
      // Not a camp kind at all.
      const CampCandidate(lat: 46.403, lon: -121.40, kind: 'spring'),
    ]);
    expect(camps.map((c) => c.name).toList(), ['Near hut', 'Far camp']);
    expect(camps.first.distanceAlongM, closeTo(200, 25));
    expect(camps.last.distanceAlongM, closeTo(800, 25));
    expect(camps.first.offsetM, lessThan(300));
  });

  test('a degenerate route yields nothing', () {
    expect(
      campsitesAlongRoute([
        [46.4, -121.4]
      ], const [
        CampCandidate(lat: 46.4, lon: -121.4, kind: 'camp_site'),
      ]),
      isEmpty,
    );
  });
}
