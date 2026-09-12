// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:cairn/data/osm/overpass_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOverpassWays on the captured Snowgrass response', () {
    late OverpassWays result;

    setUpAll(() {
      final json = jsonDecode(
        File('test/fixtures/overpass_snowgrass.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      result = parseOverpassWays(json);
    });

    test('resolves the tagged trail ways with real geometry', () {
      expect(result.ways.length, greaterThanOrEqualTo(3));
      for (final w in result.ways) {
        expect(w.geometry.length, greaterThan(1));
        expect(w.lengthM, greaterThan(0));
        expect(w.highway, isNotEmpty);
        // bbox brackets the geometry
        for (final p in w.geometry) {
          expect(p[0], inInclusiveRange(w.minLat, w.maxLat));
          expect(p[1], inInclusiveRange(w.minLon, w.maxLon));
        }
      }
    });

    test('finds the Pacific Crest Trail', () {
      final pct = result.ways.where((w) => w.name == 'Pacific Crest Trail');
      expect(pct, isNotEmpty);
      expect(pct.first.lengthM, greaterThan(100));
    });

    test('captures route relations', () {
      expect(result.relations.length, greaterThanOrEqualTo(1));
    });
  });

  group('parseOverpassWays drops street furniture', () {
    test('sidewalks and crossings are not trails', () {
      final json = {
        'elements': [
          {'type': 'node', 'id': 1, 'lat': 47.59, 'lon': -120.66},
          {'type': 'node', 'id': 2, 'lat': 47.591, 'lon': -120.661},
          {
            'type': 'way',
            'id': 10,
            'nodes': [1, 2],
            'tags': {'highway': 'footway', 'footway': 'sidewalk'},
          },
          {
            'type': 'way',
            'id': 11,
            'nodes': [1, 2],
            'tags': {'highway': 'footway', 'footway': 'crossing'},
          },
          {
            'type': 'way',
            'id': 12,
            'nodes': [1, 2],
            'tags': {'highway': 'footway', 'name': 'River Trail'},
          },
          {
            'type': 'way',
            'id': 13,
            'nodes': [1, 2],
            'tags': {'highway': 'path', 'sac_scale': 'hiking'},
          },
        ],
      };
      final parsed = parseOverpassWays(json);
      expect(parsed.ways.map((w) => w.id).toList(), [12, 13]);
      expect(isUrbanFootway({'footway': 'access_aisle'}), isTrue);
      expect(isUrbanFootway({'highway': 'footway'}), isFalse);
    });
  });

  group('parseOverpassPois', () {
    test('maps tags to POI kinds', () {
      final json = {
        'elements': [
          {
            'type': 'node',
            'id': 1,
            'lat': 46.47,
            'lon': -121.45,
            'tags': {'natural': 'spring', 'name': 'Snowgrass Spring'},
          },
          {
            'type': 'node',
            'id': 2,
            'lat': 46.48,
            'lon': -121.46,
            'tags': {'natural': 'peak', 'name': 'Old Snowy'},
          },
          {
            'type': 'node',
            'id': 3,
            'lat': 46.49,
            'lon': -121.47,
            'tags': {'amenity': 'parking'},
          },
          {
            'type': 'node',
            'id': 4,
            'lat': 46.40,
            'lon': -121.40,
            'tags': {'shop': 'supermarket'}, // not a POI kind we keep
          },
        ],
      };
      final pois = parseOverpassPois(json);
      expect(pois.length, 3);
      expect(pois.firstWhere((p) => p.id == 'n1').kind, 'spring');
      expect(pois.firstWhere((p) => p.id == 'n2').kind, 'peak');
      expect(pois.firstWhere((p) => p.id == 'n3').kind, 'parking');
    });
  });
}
