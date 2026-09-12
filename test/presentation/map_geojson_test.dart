// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/models/poi.dart';
import 'package:cairn/domain/models/trail.dart';
import 'package:cairn/presentation/map_common/map_geojson.dart';
import 'package:flutter_test/flutter_test.dart';

Trail _trail(int id, {String? name}) => Trail(
      id: id,
      highway: 'path',
      lengthM: 100,
      name: name,
      geometry: const [
        [46.0, -121.0],
        [46.01, -121.01],
      ],
    );

void main() {
  group('trailsToGeoJson', () {
    test('swaps [lat,lon] geometry to [lon,lat] coordinates', () {
      final gj = trailsToGeoJson([_trail(1, name: 'A')], zoom: 15);
      final feature = (gj['features'] as List).single as Map;
      final coords = (feature['geometry'] as Map)['coordinates'] as List;
      expect(coords.first, [-121.0, 46.0]); // lon first
    });

    test('drops unnamed ways below z11 but keeps them higher', () {
      final unnamed = [_trail(1)];
      expect((trailsToGeoJson(unnamed, zoom: 9)['features'] as List), isEmpty);
      expect((trailsToGeoJson(unnamed, zoom: 13)['features'] as List),
          hasLength(1));
    });

    test('caps the feature collection at maxTrailFeatures', () {
      final many = [
        for (var i = 0; i < maxTrailFeatures + 100; i++) _trail(i, name: 'T$i')
      ];
      final gj = trailsToGeoJson(many, zoom: 15);
      expect((gj['features'] as List), hasLength(maxTrailFeatures));
    });
  });

  group('trailsSignature', () {
    test('is stable for the same set and zoom bucket', () {
      final trails = [_trail(1, name: 'A'), _trail(2, name: 'B')];
      expect(trailsSignature(trails, 14), trailsSignature(trails, 14));
      // 13 and 14 share the <15 bucket, so the signature is unchanged.
      expect(trailsSignature(trails, 14), trailsSignature(trails, 13));
    });

    test('changes when the id set changes', () {
      final a = [_trail(1, name: 'A')];
      final b = [_trail(2, name: 'A')];
      expect(trailsSignature(a, 14), isNot(trailsSignature(b, 14)));
    });

    test('changes across a zoom bucket boundary', () {
      final trails = [_trail(1, name: 'A')];
      // z9 is the named-only bucket, z14 is not.
      expect(trailsSignature(trails, 9), isNot(trailsSignature(trails, 14)));
    });
  });

  group('poisToGeoJson', () {
    test('draws springs, peaks and named lakes but never streams', () {
      const pois = [
        PoiPoint(id: 'n1', kind: 'spring', lat: 46.4, lon: -121.4),
        PoiPoint(id: 'w2', kind: 'stream', lat: 46.41, lon: -121.4),
        PoiPoint(id: 'w3', kind: 'river', lat: 46.42, lon: -121.4),
        PoiPoint(id: 'w4', kind: 'water', lat: 46.43, lon: -121.4),
        PoiPoint(
            id: 'w5',
            kind: 'water',
            lat: 46.44,
            lon: -121.4,
            name: 'Goat Lake'),
        PoiPoint(id: 'n6', kind: 'peak', lat: 46.45, lon: -121.4, name: 'Pk'),
      ];
      final features = poisToGeoJson(pois)['features'] as List;
      final ids = [for (final f in features) f['properties']['id']];
      expect(ids, ['n1', 'w5', 'n6']);
      expect(features.first['properties']['icon'], 'water');
    });
  });
}
