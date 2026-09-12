// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/models/trail.dart';
import 'package:cairn/presentation/explore/nearby_trails_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A 60 mi north-south trail, one vertex per km.
  final longGeometry = [
    for (var i = 0; i <= 96; i++) [46.0 + i * 0.009, -121.4],
  ];
  final pct = Trail(
    id: 1,
    highway: 'path',
    lengthM: 96000,
    name: 'Pacific Crest Trail',
    geometry: longGeometry,
  );
  // The viewport sees 46.40 to 46.44.
  const viewport = [46.40, -121.45, 46.44, -121.35];

  test('a trail over 30 mi becomes a section in view', () {
    final entry =
        buildNearbyTrail([pct], 46.42, -121.4, viewportBbox: viewport);
    expect(entry.sectionInView, isTrue);
    // The clipped run covers the viewport plus 25% and a vertex of margin.
    expect(entry.lengthM, lessThan(10000));
    expect(entry.lengthM, greaterThan(3000));
    expect(entry.navGeometry.length, lessThan(longGeometry.length));
    expect(entry.geometry.first[0], lessThanOrEqualTo(46.40));
    expect(entry.geometry.last[0], greaterThanOrEqualTo(46.44));
  });

  test('a short trail is never a section', () {
    final short = pct.copyWith(
      lengthM: 5000,
      geometry: longGeometry.take(6).toList(),
    );
    final entry =
        buildNearbyTrail([short], 46.02, -121.4, viewportBbox: viewport);
    expect(entry.sectionInView, isFalse);
    expect(entry.lengthM, 5000);
  });

  test('without a viewport the whole trail is listed', () {
    final entry = buildNearbyTrail([pct], 46.42, -121.4);
    expect(entry.sectionInView, isFalse);
    expect(entry.lengthM, 96000);
  });

  test('buildNearbyTrails flags the long trail and keeps the order by distance',
      () {
    const near = Trail(
      id: 2,
      highway: 'path',
      lengthM: 1200,
      name: 'Short Loop',
      geometry: [
        [46.42, -121.4],
        [46.425, -121.4],
      ],
    );
    final list =
        buildNearbyTrails([pct, near], 46.42, -121.4, viewportBbox: viewport);
    expect(list.length, 2);
    expect(list.first.name, 'Short Loop');
    expect(list.last.sectionInView, isTrue);
  });
}
