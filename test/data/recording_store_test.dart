// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'package:cairn/core/geo/tile_math.dart';
import 'package:cairn/data/recording/recording_log.dart';
import 'package:cairn/data/recording/recording_session.dart';
import 'package:cairn/data/sources/terrain_sidecar.dart';
import 'package:cairn/domain/usecases/recording_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cairn_rec_');
  });
  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows can hold a handle briefly
    }
  });

  test('session file round-trips and survives a torn write', () async {
    final session = RecordingSession(
      trackId: 'abc',
      name: 'Hike',
      startedAt: DateTime(2026, 9, 11, 8),
      logPath: RecordingSession.logPathFor(dir, 'abc'),
      terrainDir: p.join(dir.path, 'terrain'),
      options: const RecordingEngineOptions(autoPause: false),
      profile: RecordingProfile.balanced,
      labels: const {'title': 'Recording'},
      metric: true,
      packKg: 8,
      route: const [
        [46.0, -121.0],
        [46.001, -121.0],
      ],
      routeElev: const [1000, 1010],
      batteryStartPct: 88,
    );
    final file = RecordingSession.fileFor(dir, 'abc');
    await session.write(file);
    final back = await RecordingSession.read(file);
    expect(back, isNotNull);
    expect(back!.trackId, 'abc');
    expect(back.profile, RecordingProfile.balanced);
    expect(back.options.autoPause, isFalse);
    expect(back.route, hasLength(2));
    expect(back.routeElev, [1000, 1010]);
    expect(back.batteryStartPct, 88);
    expect(back.metric, isTrue);
    expect(back.status, RecordingSessionStatus.active);

    // Only the .tmp exists after a kill mid-write: read reports no session.
    await file.delete();
    await File('${file.path}.tmp').writeAsString('{"trackId":');
    expect(await RecordingSession.read(file), isNull);
  });

  test('log writer appends and the replay restores the engine', () async {
    final logFile = File(p.join(dir.path, 'rec.jsonl'));
    final writer = RecordingLogWriter(logFile);
    await writer.open();
    final t0 = DateTime.utc(2026, 9, 11, 8);
    final engine = RecordingEngine(startedAt: t0);
    for (var i = 0; i < 5; i++) {
      engine.addFix(RecordingSample(
        t: t0.add(Duration(seconds: i * 10)),
        lat: 46.0 + i * 0.0001,
        lon: -121.0,
        accuracyM: 5,
        speedMps: 1.1,
      ));
      await writer.append(engine.drainLogLines());
    }
    await writer.close();

    final restored = RecordingEngine(startedAt: t0);
    final n = await replayRecordingLog(logFile, restored);
    expect(n, 5);
    expect(restored.points.length, 5);
    expect(restored.stats(t0.add(const Duration(seconds: 40))).distanceM,
        engine.stats(t0.add(const Duration(seconds: 40))).distanceM);
  });

  test('terrain sidecar writes next to the PNG and reads back bilinearly',
      () async {
    // The z14 tile under a point near Packwood, WA, and a second point 2 px
    // east inside the same tile.
    final px = latLonToPixel(46.435, -122.425, 14);
    final t = px.tile;
    final png = p.join(dir.path, 'terrain', '${t.z}', '${t.x}', '${t.y}.png');
    final grid = Float32List(256 * 256);
    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        grid[y * 256 + x] = 1000.0 + x; // rises 1 m per pixel eastward
      }
    }
    await TerrainSidecarReader.writeSidecar(png, grid);
    expect(File(TerrainSidecarReader.sidecarPathFor(png)).existsSync(), isTrue);

    final reader = TerrainSidecarReader(Directory(p.join(dir.path, 'terrain')));
    final a = reader.elevationAt(46.435, -122.425);
    expect(a, isNotNull);
    expect(a!, closeTo(1000 + px.px, 1.0));
    final east = reader.elevationAt(46.435, -122.425 + 0.0003);
    if (east != null) expect(east, greaterThan(a)); // same tile: higher
    expect(reader.elevationAt(0, 0), isNull); // no sidecar for that tile
  });
}
