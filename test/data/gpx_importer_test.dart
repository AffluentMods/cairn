// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/db/app_database.dart';
import 'package:cairn/data/gpx/gpx_codec.dart';
import 'package:cairn/data/gpx/gpx_importer.dart';
import 'package:cairn/data/repositories/route_repository_impl.dart';
import 'package:cairn/data/repositories/track_repository_impl.dart';
import 'package:cairn/data/repositories/user_waypoints_repository.dart';
import 'package:cairn/domain/repositories/elevation_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FlatElevation implements ElevationRepository {
  @override
  Future<double?> elevationAt(double lat, double lon) async => 1000;

  @override
  Future<List<double>> elevationsAlong(List<List<double>> points) async =>
      List<double>.filled(points.length, 1000);
}

const _routeWithPins = '''
<?xml version="1.0"?>
<gpx version="1.1" creator="CalTopo" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="46.40" lon="-121.40"><name>Goat Creek</name><desc>Reliable</desc><type>water</type></wpt>
  <wpt lat="46.41" lon="-121.41"><name>Camp 1</name><sym>Campground</sym></wpt>
  <rte><name>Snowgrass</name>
    <rtept lat="46.40" lon="-121.40"></rtept>
    <rtept lat="46.41" lon="-121.41"></rtept>
    <rtept lat="46.42" lon="-121.42"></rtept>
  </rte>
</gpx>''';

const _pinsOnly = '''
<?xml version="1.0"?>
<gpx version="1.1" creator="test" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="46.50" lon="-121.50"><name>Rockfall</name><type>hazard</type></wpt>
</gpx>''';

void main() {
  late AppDatabase db;
  late GpxImporter importer;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    importer = GpxImporter(
      routes: RouteRepositoryImpl(db),
      tracks: TrackRepositoryImpl(db),
      elevation: _FlatElevation(),
      userWaypoints: UserWaypointsRepository(db),
    );
  });

  tearDown(() => db.close());

  test('wpt pins are saved as user waypoints attached to the route', () async {
    final summary =
        await importer.import(parseGpx(_routeWithPins), fallbackName: 'file');
    expect(summary.routes, 1);
    expect(summary.tracks, 0);
    expect(summary.waypoints, 2);

    final routes = await db.select(db.routes).get();
    expect(routes.length, 1);
    expect(routes.first.name, 'Snowgrass');

    final pins = await db.select(db.userWaypoints).get();
    expect(pins.length, 2);
    expect(pins.every((p) => p.routeId == routes.first.id), isTrue);
    final water = pins.firstWhere((p) => p.name == 'Goat Creek');
    expect(water.kind, 'water');
    expect(water.note, 'Reliable');
    final camp = pins.firstWhere((p) => p.name == 'Camp 1');
    expect(camp.kind, 'camp'); // from <sym>Campground</sym>
    expect(camp.note, isNull);
  });

  test('a file with only pins imports them as standalone waypoints', () async {
    final data = parseGpx(_pinsOnly);
    expect(data.isEmpty, isFalse);
    final summary = await importer.import(data, fallbackName: 'file');
    expect(summary.total, 0);
    expect(summary.waypoints, 1);
    final pins = await db.select(db.userWaypoints).get();
    expect(pins.single.routeId, isNull);
    expect(pins.single.kind, 'hazard');
  });

  test('without a waypoint repository the pins are simply not saved', () async {
    final plain = GpxImporter(
      routes: RouteRepositoryImpl(db),
      tracks: TrackRepositoryImpl(db),
      elevation: _FlatElevation(),
    );
    final summary =
        await plain.import(parseGpx(_routeWithPins), fallbackName: 'file');
    expect(summary.routes, 1);
    expect(summary.waypoints, 0);
  });
}
