// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:cairn/data/usfs/mvum_parser.dart';
import 'package:cairn/domain/models/forest_road.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json =
      jsonDecode(File('test/fixtures/mvum_roads.json').readAsStringSync())
          as Map<String, dynamic>;

  test('route numbers print like the paper map', () {
    expect(forestRoadNumber('2100000'), '2100');
    expect(forestRoadNumber('2100011'), '2100-011');
    expect(forestRoadNumber('4840000'), '4840');
    expect(forestRoadNumber('1151A'), '1151A');
    expect(forestRoadNumber(' 2100084 '), '2100-084');
  });

  test('names are title-cased, keeping hyphenated parts', () {
    expect(titleCase('METZLER'), 'Metzler');
    expect(titleCase('JOHNSON CREEK SNO-PARK'), 'Johnson Creek Sno-Park');
    expect(titleCase('ROAD TO THE LAKE'), 'Road to the Lake');
  });

  test('parses roads with access, season, surface, and parts', () {
    final page = parseMvum(json, trails: false);
    expect(page.exceeded, isFalse);
    final byId = {for (final r in page.roads) r.id: r};
    // 3 single-part roads plus a 2-part seasonal one.
    expect(page.roads.length, 5);

    final spur = byId['r2100011']!;
    expect(spur.number, '2100-011');
    expect(spur.name, 'Metzler');
    expect(spur.kind, 'road');
    expect(spur.seasonal, isFalse);
    expect(spur.surfaceCode, 'NAT');
    expect(spur.maintLevelCode, '2');
    expect(spur.access.map((a) => a.vehicle),
        ['passengerVehicle', 'highClearance']);
    expect(spur.access.every((a) => a.yearlong), isTrue);
    expect(spur.geometry.first.length, 2);
    // [lat, lon] order: latitude first, in the Cascades.
    expect(spur.geometry.first[0], closeTo(46.6, 0.2));
    expect(spur.geometry.first[1], closeTo(-121.6, 0.2));

    final main = byId['r2100000']!;
    expect(main.number, '2100');
    expect(main.name, 'Cispus');
    expect(main.seasonal, isTrue);
    expect(main.access.first.dates, '04/01-11/30');
    expect(main.access.first.yearlong, isFalse);
    expect(main.lengthMi, 1.5);
    expect(byId['r2100000#1']!.geometry.length, 2);
  });

  test('the trails layer gets the trail prefix and kind', () {
    final page = parseMvum(json, trails: true);
    expect(page.roads.first.id, startsWith('t'));
    expect(page.roads.first.kind, 'trail');
    expect(page.roads.first.isTrail, isTrue);
  });

  test('exceededTransferLimit is read from either place ArcGIS puts it', () {
    expect(
      parseMvum({'features': [], 'exceededTransferLimit': true}, trails: false)
          .exceeded,
      isTrue,
    );
    expect(
      parseMvum({
        'features': [],
        'properties': {'exceededTransferLimit': true}
      }, trails: false)
          .exceeded,
      isTrue,
    );
    expect(parseMvum({'features': []}, trails: false).exceeded, isFalse);
  });

  test('a RoadAccess with the yearlong marker reads as all year', () {
    const a = RoadAccess(vehicle: 'atv', dates: 'yearlong');
    expect(a.yearlong, isTrue);
  });
}
