// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/platform/battery_level.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/recording/recording_log.dart';
import '../../data/recording/recording_session.dart';
import '../../data/sources/location_source.dart';
import '../../data/sources/terrain_sidecar.dart';
import '../../domain/usecases/recording_engine.dart';

/// Commands the main isolate sends the task with
/// `FlutterForegroundTask.sendDataToTask({'cmd': ..., 'value': ...})`.
abstract final class RecordingCommand {
  static const pause = 'pause';
  static const resume = 'resume';
  static const mute = 'mute';
  static const snapshot = 'snapshot';
  static const profile = 'profile';

  /// Asks for every accepted fix so far (the traveled path on the map after
  /// the app re-attaches).
  static const polyline = 'polyline';
}

/// Messages the task sends the main isolate, JSON-encoded: `snapshot` carries
/// a [RecordingSnapshot] under `data` plus the active `profile`; `polyline`
/// carries `[[lat, lon], ...]`; `stop` means the hiker pressed Stop on the
/// notification.
abstract final class RecordingMessage {
  static const snapshot = 'snapshot';
  static const polyline = 'polyline';
  static const stop = 'stop';
}

const _channelId = 'cairn_recording';
const _serviceId = 261;
const _buttonToggle = 'toggle';
const _buttonStop = 'stop';

/// The white cairn drawable declared as manifest meta-data (Android draws
/// the launcher icon otherwise, which reads as a blob in the status bar).
const _notificationIcon = NotificationIcon(
  metaDataName: 'com.affluentlabs.cairn.NOTIFICATION_ICON',
);

/// The foreground service entry point. Must be top-level.
@pragma('vm:entry-point')
void startRecordingCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}

/// Registers the notification channel and the 5 s tick. Call before
/// [startRecordingService]; [channelName] is the localized channel title
/// Android shows in its notification settings.
void initRecordingService({required String channelName}) {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: _channelId,
      channelName: channelName,
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      // The tick runs auto-pause when no fixes arrive (a stationary phone
      // under a distance filter sends nothing) and refreshes the
      // notification. 5 s keeps wakeups rare; the clock itself is computed
      // from timestamps, not ticks.
      eventAction: ForegroundTaskEventAction.repeat(5000),
      allowWakeLock: true,
    ),
  );
}

/// Starts the service for the session already written to disk and pointed to
/// by [kActiveRecordingKey]. The handler reads the session file itself.
Future<bool> startRecordingService({
  required String title,
  required String text,
  required String pauseLabel,
  required String stopLabel,
}) async {
  if (await FlutterForegroundTask.isRunningService) return true;
  final result = await FlutterForegroundTask.startService(
    serviceId: _serviceId,
    notificationTitle: title,
    notificationText: text,
    notificationIcon: _notificationIcon,
    notificationButtons: [
      NotificationButton(id: _buttonToggle, text: pauseLabel),
      NotificationButton(id: _buttonStop, text: stopLabel),
    ],
    callback: startRecordingCallback,
  );
  return result is ServiceRequestSuccess;
}

Future<void> stopRecordingService() async {
  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.stopService();
  }
}

/// Location settings for a power profile (docs/DECISIONS.md). Precise is the
/// spec's best accuracy at 5 m; Balanced and Saver raise the distance filter
/// and interval so the radio wakes less often.
LocationSettings locationSettingsFor(RecordingProfile profile) {
  if (Platform.isAndroid) {
    return switch (profile) {
      RecordingProfile.precise => AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 1),
        ),
      RecordingProfile.balanced => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 4),
        ),
      RecordingProfile.saver => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 30,
          intervalDuration: const Duration(seconds: 15),
        ),
    };
  }
  return switch (profile) {
    RecordingProfile.precise => const LocationSettings(
        accuracy: LocationAccuracy.best, distanceFilter: 5),
    RecordingProfile.balanced => const LocationSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 10),
    RecordingProfile.saver => const LocationSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 30),
  };
}

/// The recording, owned by the foreground service isolate (spec Phase 6: "the
/// handler owns the write, the UI just reads"). It reads the session file,
/// replays the durable log (so a restart after a kill resumes exactly), runs
/// the GPS stream through [RecordingEngine], appends every accepted fix and
/// pause transition to the log, sends snapshots to the main isolate, and keeps
/// the notification (distance, time, state, Pause/Resume and Stop buttons)
/// current. It never touches the database: the main isolate ingests the log
/// when the hike is finished, or on the next launch if the app was gone.
class RecordingTaskHandler extends TaskHandler {
  RecordingSession? _session;
  RecordingEngine? _engine;
  StreamSubscription<Position>? _sub;
  RecordingLogWriter? _log;
  TerrainSidecarReader? _dem;
  RecordingProfile? _activeProfile;
  int _ticks = 0;
  String? _lastNotification;
  bool _stopping = false;
  Future<void> _logChain = Future.value();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final path =
        await FlutterForegroundTask.getData<String>(key: kActiveRecordingKey);
    final session =
        path == null ? null : await RecordingSession.read(File(path));
    if (session == null || session.status != RecordingSessionStatus.active) {
      await FlutterForegroundTask.stopService();
      return;
    }
    _session = session;
    _dem = TerrainSidecarReader(Directory(session.terrainDir));
    final engine = session.newEngine();
    // A restart after the process was killed, or Resume after a recovery:
    // the log holds everything so far.
    await replayRecordingLog(File(session.logPath), engine);
    _engine = engine;
    _log = RecordingLogWriter(File(session.logPath));
    await _log!.open();
    await _startLocation(session.profile);
    _pushSnapshot();
    await _refreshNotification(force: true);
  }

  Future<void> _startLocation(RecordingProfile profile) async {
    await _sub?.cancel();
    final session = _session;
    if (session == null) return;
    _activeProfile = profile;
    final LocationSource source;
    final route = session.route;
    if (kDebugMode && session.simulate && route != null && route.length >= 2) {
      source = SimulatedLocationSource(route);
    } else {
      source = DeviceLocationSource(settings: locationSettingsFor(profile));
    }
    _sub = source.stream().listen(_onPosition, onError: (Object _) {});
  }

  void _onPosition(Position pos) {
    final engine = _engine;
    final session = _session;
    if (engine == null || session == null || _stopping) return;
    final sample = RecordingSample(
      t: pos.timestamp,
      lat: pos.latitude,
      lon: pos.longitude,
      accuracyM: pos.accuracy > 0 ? pos.accuracy : null,
      speedMps: pos.speed >= 0 ? pos.speed : null,
      // Simulated fixes and receivers with no altitude report 0; feed nothing
      // rather than a 0 m elevation.
      elevM: session.simulate || pos.altitude == 0 ? null : pos.altitude,
    );
    final heading = pos.heading > 0 && pos.speed > 0.5 ? pos.heading : null;
    final dem = _dem?.elevationAt(pos.latitude, pos.longitude);
    final before = engine.phase;
    final wasOnRoute = engine.onRoute;
    engine.addFix(sample, demAltM: dem, heading: heading);
    _appendLog(engine.drainLogLines());
    _pushSnapshot();
    if (engine.phase != before || engine.onRoute != wasOnRoute) {
      unawaited(_refreshNotification(force: true));
    }
  }

  /// Log appends are serialized so lines never interleave.
  void _appendLog(List<String> lines) {
    if (lines.isEmpty) return;
    final log = _log;
    if (log == null) return;
    _logChain = _logChain.then((_) => log.append(lines));
  }

  void _pushSnapshot() {
    final engine = _engine;
    if (engine == null) return;
    final snap = engine.snapshot(DateTime.now());
    FlutterForegroundTask.sendDataToMain(jsonEncode({
      'type': RecordingMessage.snapshot,
      'profile': _activeProfile?.name,
      'data': snap.toJson(),
    }));
  }

  Future<void> _refreshNotification({bool force = false}) async {
    final engine = _engine;
    final session = _session;
    if (engine == null || session == null || _stopping) return;
    final labels = session.labels;
    final fmt =
        UnitFormatter(session.metric ? UnitSystem.metric : UnitSystem.imperial);
    final stats = engine.stats(DateTime.now());
    var text = (labels['body'] ?? '{d}, {t}')
        .replaceAll('{d}', fmt.distance(stats.distanceM))
        .replaceAll(
          '{t}',
          UnitFormatter.durationClock(Duration(seconds: stats.totalSeconds)),
        );
    final stateLabel = switch (engine.phase) {
      RecordingPhase.recording => null,
      RecordingPhase.paused => labels['paused'],
      RecordingPhase.autoPaused => labels['autoPaused'],
    };
    if (stateLabel != null) text = '$stateLabel · $text';
    final off = engine.offRouteDistanceM;
    if (!engine.onRoute && off != null) {
      final offText = (labels['offRoute'] ?? 'Off route by {d}')
          .replaceAll('{d}', fmt.distance(off));
      text = '$offText · $text';
    }
    final toggle = engine.phase == RecordingPhase.recording
        ? (labels['pause'] ?? 'Pause')
        : (labels['resume'] ?? 'Resume');
    final key = '$text|$toggle';
    if (!force && key == _lastNotification) return;
    _lastNotification = key;
    await FlutterForegroundTask.updateService(
      notificationTitle: labels['title'] ?? 'Recording',
      notificationText: text,
      notificationIcon: _notificationIcon,
      notificationButtons: [
        NotificationButton(id: _buttonToggle, text: toggle),
        NotificationButton(id: _buttonStop, text: labels['stop'] ?? 'Stop'),
      ],
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final engine = _engine;
    if (engine == null || _stopping) return;
    final before = engine.phase;
    engine.tick(DateTime.now());
    _appendLog(engine.drainLogLines());
    _ticks++;
    _pushSnapshot();
    final changed = engine.phase != before;
    if (changed || _ticks % 3 == 0) {
      unawaited(_refreshNotification(force: changed));
    }
    if (_ticks % 60 == 0) unawaited(_checkBattery());
  }

  /// Drops to the Saver profile below 20 percent when the setting is on.
  Future<void> _checkBattery() async {
    final session = _session;
    if (session == null || !session.autoSaver) return;
    if (_activeProfile == RecordingProfile.saver) return;
    final pct = await readBatteryPercent();
    if (pct != null && pct <= 20) {
      await _startLocation(RecordingProfile.saver);
      _pushSnapshot();
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final engine = _engine;
    if (engine == null || _stopping) return;
    final now = DateTime.now();
    switch (data['cmd']) {
      case RecordingCommand.pause:
        engine.pause(now);
      case RecordingCommand.resume:
        engine.resume(now);
      case RecordingCommand.mute:
        engine.muteOffRoute(now);
      case RecordingCommand.profile:
        final name = data['value'];
        for (final p in RecordingProfile.values) {
          if (p.name == name) unawaited(_startLocation(p));
        }
      case RecordingCommand.snapshot:
        break;
      case RecordingCommand.polyline:
        FlutterForegroundTask.sendDataToMain(jsonEncode({
          'type': RecordingMessage.polyline,
          'data': [
            for (final p in engine.points)
              [
                double.parse(p.lat.toStringAsFixed(6)),
                double.parse(p.lon.toStringAsFixed(6)),
              ],
          ],
        }));
        return;
    }
    _appendLog(engine.drainLogLines());
    _pushSnapshot();
    unawaited(_refreshNotification(force: true));
  }

  @override
  void onNotificationButtonPressed(String id) {
    final engine = _engine;
    if (engine == null || _stopping) return;
    if (id == _buttonToggle) {
      final now = DateTime.now();
      if (engine.phase == RecordingPhase.recording) {
        engine.pause(now);
      } else {
        engine.resume(now);
      }
      _appendLog(engine.drainLogLines());
      _pushSnapshot();
      unawaited(_refreshNotification(force: true));
    } else if (id == _buttonStop) {
      unawaited(_stopFromNotification());
    }
  }

  /// Stop pressed on the notification. Marks the session stopped so the next
  /// app launch ingests it even if the app is not running, tells the main
  /// isolate (which finishes now if it is alive), and ends the service.
  Future<void> _stopFromNotification() async {
    final session = _session;
    if (session == null) return;
    _stopping = true;
    await _sub?.cancel();
    _sub = null;
    _appendLog(_engine?.drainLogLines() ?? const []);
    await _logChain;
    await _log?.close();
    _log = null;
    final path =
        await FlutterForegroundTask.getData<String>(key: kActiveRecordingKey);
    if (path != null) {
      await session
          .copyWith(
            status: RecordingSessionStatus.stopped,
            endedAt: DateTime.now(),
          )
          .write(File(path));
    }
    FlutterForegroundTask.sendDataToMain(
        jsonEncode({'type': RecordingMessage.stop}));
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _sub?.cancel();
    _sub = null;
    _appendLog(_engine?.drainLogLines() ?? const []);
    await _logChain;
    await _log?.close();
    _log = null;
  }
}
