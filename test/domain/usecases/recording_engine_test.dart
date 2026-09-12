// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/data/recording/recording_log.dart';
import 'package:cairn/domain/usecases/recording_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 11, 8);

  /// A straight trail heading north, one vertex every ~11 m, climbing 1 m per
  /// vertex, [n] vertices long.
  List<List<double>> northRoute(int n) => [
        for (var i = 0; i < n; i++) [46.0 + i * 0.0001, -121.0]
      ];
  List<double> climb(int n) => [for (var i = 0; i < n; i++) 1000.0 + i];

  RecordingSample fix(int sec, double lat, double lon,
          {double acc = 6, double? speed, double? elev}) =>
      RecordingSample(
        t: t0.add(Duration(seconds: sec)),
        lat: lat,
        lon: lon,
        accuracyM: acc,
        speedMps: speed,
        elevM: elev,
      );

  group('filters and stats', () {
    test('accumulates distance, moving time, DEM gain; drops junk', () {
      final e = RecordingEngine(startedAt: t0);
      var accepted = 0;
      for (var i = 0; i < 6; i++) {
        // ~11 m every 10 s at 1.1 m/s, DEM climbing 6 m per step.
        if (e.addFix(fix(i * 10, 46.0 + i * 0.0001, -121.0),
            demAltM: 1000 + i * 6.0)) {
          accepted++;
        }
      }
      expect(accepted, 6);
      final s = e.stats(t0.add(const Duration(seconds: 50)));
      expect(s.distanceM, closeTo(55.6, 1.0));
      expect(s.movingSeconds, 50);
      expect(s.totalSeconds, 50);
      expect(s.gainM, closeTo(30, 0.01));
      expect(s.pointCount, 6);

      // Low accuracy and a 1 km jump in a second are both rejected.
      expect(e.addFix(fix(60, 46.001, -121.0, acc: 80)), isFalse);
      expect(e.addFix(fix(61, 46.02, -121.0)), isFalse);
    });

    test('GPS altitude uses a 5-point median, never raw deltas', () {
      final e = RecordingEngine(startedAt: t0);
      // Flat walk with one 40 m GPS altitude spike: raw deltas would count
      // 40 up and 40 down; the median throws the spike away.
      final alts = <double>[1000, 1001, 1040, 1000, 1001, 1000, 1001, 1000];
      for (var i = 0; i < alts.length; i++) {
        e.addFix(fix(i * 10, 46.0 + i * 0.0001, -121.0, elev: alts[i]));
      }
      final s = e.stats(t0.add(const Duration(seconds: 80)));
      expect(s.gainM, 0);
      expect(s.lossM, 0);
    });

    test('first DEM reading after GPS-only samples re-anchors, no phantom drop',
        () {
      final e = RecordingEngine(startedAt: t0);
      // GPS reports ellipsoid heights ~20 m above the terrain.
      e.addFix(fix(0, 46.0000, -121.0, elev: 1020));
      e.addFix(fix(10, 46.0001, -121.0, elev: 1020));
      // Tiles become available: DEM says 1000. Not a 20 m loss.
      e.addFix(fix(20, 46.0002, -121.0, elev: 1020), demAltM: 1000);
      e.addFix(fix(30, 46.0003, -121.0, elev: 1030), demAltM: 1010);
      final s = e.stats(t0.add(const Duration(seconds: 30)));
      expect(s.lossM, 0);
      expect(s.gainM, closeTo(10, 0.01));
    });
  });

  group('auto-pause', () {
    test('pauses within 20 s of standing still and resumes on walking', () {
      final e = RecordingEngine(startedAt: t0);
      for (var i = 0; i < 4; i++) {
        e.addFix(fix(i * 10, 46.0 + i * 0.0001, -121.0, speed: 1.1));
      }
      expect(e.phase, RecordingPhase.recording);
      // Standing still: no fixes arrive (distance filter). The clock ticks.
      e.tick(t0.add(const Duration(seconds: 45)));
      expect(e.phase, RecordingPhase.recording);
      e.tick(t0.add(const Duration(seconds: 51)));
      expect(e.phase, RecordingPhase.autoPaused);
      final snap = e.snapshot(t0.add(const Duration(seconds: 52)));
      expect(snap.events, contains('autoPaused'));

      // Active time stops while paused.
      final paused = e.stats(t0.add(const Duration(seconds: 120)));
      expect(paused.totalSeconds, 51);
      expect(paused.currentSpeedMps, 0);

      // Two moving fixes resume; the distance walked from the pause spot
      // counts, the wait does not.
      expect(e.addFix(fix(121, 46.00031, -121.0, speed: 1.2)), isFalse);
      expect(e.addFix(fix(122, 46.00040, -121.0, speed: 1.2)), isTrue);
      expect(e.phase, RecordingPhase.recording);
      final after = e.stats(t0.add(const Duration(seconds: 122)));
      expect(after.totalSeconds, 51);
      expect(after.distanceM, greaterThan(40));
      expect(after.movingSeconds, 30);
    });

    test('manual pause drops fixes and manual resume starts a new segment', () {
      final e = RecordingEngine(startedAt: t0);
      e.addFix(fix(0, 46.0000, -121.0, speed: 1.1));
      e.addFix(fix(10, 46.0001, -121.0, speed: 1.1));
      e.pause(t0.add(const Duration(seconds: 12)));
      expect(e.addFix(fix(20, 46.0002, -121.0, speed: 1.1)), isFalse);
      e.resume(t0.add(const Duration(seconds: 600)));
      e.addFix(fix(601, 46.0010, -121.0, speed: 1.1)); // 100 m away
      final s = e.stats(t0.add(const Duration(seconds: 610)));
      expect(s.distanceM, closeTo(11.1, 0.5)); // the gap is not a segment
      expect(s.totalSeconds, 22); // 12 before the pause + 10 after
    });
  });

  group('route following', () {
    test('progress, remaining, remaining gain and an ETA', () {
      final route = northRoute(101); // ~1112 m, 100 m of climb
      final e = RecordingEngine(
        startedAt: t0,
        route: route,
        routeElev: climb(101),
      );
      // Walk the first 30 vertices at 1.1 m/s.
      for (var i = 0; i <= 30; i++) {
        e.addFix(fix(i * 10, route[i][0], route[i][1], speed: 1.1),
            demAltM: 1000 + i.toDouble());
      }
      final snap = e.snapshot(t0.add(const Duration(seconds: 300)));
      expect(snap.onRoute, isTrue);
      expect(snap.progressM, closeTo(333.6, 2));
      expect(snap.remainingM, closeTo(778, 3));
      expect(snap.remainingGainM, closeTo(70, 6)); // hysteresis rounds
      expect(snap.etaSeconds, isNotNull);
      // Naismith on 778 m + 70 m: 560 s + 420 s, then scaled by pace.
      expect(snap.etaSeconds!, greaterThan(600));
      expect(snap.etaSeconds!, lessThan(1500));
      expect(snap.arrived, isFalse);
    });

    test('off route needs 60 m for 30 s with good fixes, then re-arms', () {
      final route = northRoute(50);
      final e = RecordingEngine(startedAt: t0, route: route);
      e.addFix(fix(0, route[0][0], route[0][1], speed: 1.1));
      e.addFix(fix(10, route[1][0], route[1][1], speed: 1.1));
      // Step 80 m east of the trail (0.001 deg lon at 46 N is ~77 m).
      e.addFix(fix(20, 46.0002, -120.999, speed: 1.1));
      expect(e.onRoute, isTrue); // dwell not met
      // A poor fix must not advance the dwell.
      e.addFix(fix(40, 46.0003, -120.999, acc: 28, speed: 1.1));
      e.addFix(fix(49, 46.0004, -120.999, speed: 1.1));
      expect(e.onRoute, isTrue);
      e.addFix(fix(51, 46.0005, -120.999, speed: 1.1));
      expect(e.onRoute, isFalse);
      var snap = e.snapshot(t0.add(const Duration(seconds: 51)));
      expect(snap.events, contains('offRoute'));
      expect(snap.offRouteDistanceM, greaterThan(60));
      expect(snap.bearingBackDeg, closeTo(270, 5)); // trail is due west

      // Mute, then walk back to within 30 m: on route again and re-armed.
      e.muteOffRoute(t0.add(const Duration(seconds: 52)));
      e.addFix(fix(60, 46.0006, -120.9998, speed: 1.1)); // ~15 m off
      expect(e.onRoute, isTrue);
      expect(e.offRouteMuted, isFalse);
      snap = e.snapshot(t0.add(const Duration(seconds: 60)));
      expect(snap.events, isNot(contains('offRoute')));
    });

    test('arrival fires at the end after covering 90 percent', () {
      final route = northRoute(20);
      final e = RecordingEngine(startedAt: t0, route: route);
      for (var i = 0; i < 20; i++) {
        e.addFix(fix(i * 10, route[i][0], route[i][1], speed: 1.1));
      }
      expect(e.arrived, isTrue);
      expect(e.snapshot(t0.add(const Duration(seconds: 200))).events,
          contains('arrived'));
    });
  });

  group('durable log', () {
    test('replaying the log restores identical stats and phase', () {
      final route = northRoute(40);
      final live =
          RecordingEngine(startedAt: t0, route: route, routeElev: climb(40));
      final lines = <String>[];
      for (var i = 0; i < 10; i++) {
        live.addFix(fix(i * 10, route[i][0], route[i][1], speed: 1.1),
            demAltM: 1000 + i.toDouble());
        lines.addAll(live.drainLogLines());
      }
      live.pause(t0.add(const Duration(seconds: 100)));
      live.resume(t0.add(const Duration(seconds: 160)));
      lines.addAll(live.drainLogLines());
      for (var i = 10; i < 20; i++) {
        live.addFix(
            fix(160 + (i - 10) * 10, route[i][0], route[i][1], speed: 1.1));
        lines.addAll(live.drainLogLines());
      }
      live.tick(t0.add(const Duration(seconds: 290))); // auto-pauses
      lines.addAll(live.drainLogLines());
      expect(live.phase, RecordingPhase.autoPaused);

      final restored =
          RecordingEngine(startedAt: t0, route: route, routeElev: climb(40));
      final applied = replayRecordingLines(
        [...lines, '{"p":[99,17', ''], // a torn last line is skipped
        restored,
      );
      expect(applied, lines.length);

      final now = t0.add(const Duration(seconds: 300));
      final a = live.stats(now);
      final b = restored.stats(now);
      expect(b.distanceM, a.distanceM);
      expect(b.movingSeconds, a.movingSeconds);
      expect(b.totalSeconds, a.totalSeconds);
      expect(b.gainM, a.gainM);
      expect(b.pointCount, a.pointCount);
      expect(restored.phase, live.phase);
      expect(restored.progressM, live.progressM);
      expect(restored.points.length, 20);
      // Replay emits no events and no new log lines.
      expect(restored.snapshot(now).events, isEmpty);
      expect(restored.drainLogLines(), isEmpty);
    });

    test('snapshot round-trips through JSON', () {
      final e = RecordingEngine(startedAt: t0, route: northRoute(10));
      e.addFix(fix(0, 46.0, -121.0, speed: 1.0), demAltM: 1000, heading: 12);
      final snap = e.snapshot(t0.add(const Duration(seconds: 5)));
      final back = RecordingSnapshot.fromJson(snap.toJson());
      expect(back.phase, snap.phase);
      expect(back.stats.distanceM, snap.stats.distanceM);
      expect(back.heading, 12);
      expect(back.progressM, snap.progressM);
      expect(back.remainingM, snap.remainingM);
    });
  });
}
