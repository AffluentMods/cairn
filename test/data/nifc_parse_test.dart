// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:cairn/data/sources/nifc_source.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  // The fixtures mirror the live WFIGS layers as of 2026-09-11: incident
  // points use plain IRWIN field names; perimeters prefix them with attr_ and
  // their own polygon fields with poly_ (docs/API_NOTES.md).
  final perimeters = _fixture('wfigs_perimeters.json');
  final incidents = _fixture('wfigs_incidents.json');

  test('incident points parse the live (unprefixed) field names', () {
    final fires = parseFires(incidents: incidents);
    expect(fires.length, 3);
    final tom = fires.firstWhere((f) => f.name == 'Mount Tom Creek');
    expect(tom.acres, 69);
    expect(tom.percentContained, isNull);
    expect(tom.unitId, 'WAOLP');
    expect(tom.irwinId, '7A4391A9-652A-4A28-BEDE-9856383B4CB4');
    expect(tom.discoveredAt,
        DateTime.fromMillisecondsSinceEpoch(1782329400000, isUtc: true));
    expect(tom.modifiedAt,
        DateTime.fromMillisecondsSinceEpoch(1789066337120, isUtc: true));
    expect(tom.lat, closeTo(47.8223, 1e-3));
    expect(tom.lon, closeTo(-123.7997, 1e-3));
    expect(tom.isPerimeter, isFalse);
    expect(tom.prescribed, isFalse);

    final rx = fires.firstWhere((f) => f.name == 'Cispus Rx');
    expect(rx.prescribed, isTrue);
    expect(rx.acres, 1200);
    expect(rx.percentContained, 40);
    expect(rx.behavior, 'Minimal');
  });

  test('perimeters parse poly_/attr_ fields and prefer the IRWIN name', () {
    final fires = parseFires(perimeters: perimeters);
    expect(fires.length, 2);
    final tom = fires.first;
    expect(tom.name, 'Mount Tom Creek');
    expect(tom.acres, 86);
    expect(tom.behavior, 'Creeping');
    expect(tom.unitId, 'WAOLP');
    expect(tom.isPerimeter, isTrue);
    expect(tom.polygons.length, 1);
    expect(tom.polygons.first.first, [47.81, -123.81]); // [lat, lon]

    final backbone = fires.last;
    // attr_ name "BACKBONE" is shouting, so the cased poly_ name is shown.
    expect(backbone.name, 'Backbone');
    expect(backbone.polygons.length, 2); // MultiPolygon outer rings
    expect(backbone.percentContained, 90);
    expect(backbone.modifiedAt,
        DateTime.fromMillisecondsSinceEpoch(1789050000000, isUtc: true));
  });

  test('a point is dropped when its perimeter is listed (IRWIN id or name)',
      () {
    final fires = parseFires(perimeters: perimeters, incidents: incidents);
    // Mount Tom Creek: matched by IRWIN id even though the poly_ name
    // ("Mt Toms Creek") differs. Backbone: matched by name (no IRWIN id).
    expect(fires.map((f) => f.name).toList(),
        ['Mount Tom Creek', 'Backbone', 'Cispus Rx']);
    expect(fires.where((f) => f.isPerimeter).length, 2);
  });

  test('fire names: shouting IRWIN names get a cased alternative or title case',
      () {
    expect(displayFireName('HIGH LAVA', null), 'High Lava');
    expect(displayFireName('BACKBONE', 'Backbone'), 'Backbone');
    expect(
        displayFireName('Mount Tom Creek', 'Mt Toms Creek'), 'Mount Tom Creek');
    expect(displayFireName('CISPUS RX', null), 'Cispus RX');
    expect(displayFireName(null, 'Mt Toms Creek'), 'Mt Toms Creek');
    expect(displayFireName(null, null), 'Fire');
    expect(displayFireName('  ', ''), 'Fire');
  });

  test('missing or empty layers yield an empty list, not a crash', () {
    expect(parseFires(), isEmpty);
    expect(parseFires(perimeters: {'features': []}, incidents: {}), isEmpty);
  });
}
