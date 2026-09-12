// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/usecases/recording_engine.dart';

/// SharedPreferences key (via FlutterForegroundTask.saveData) holding the path
/// of the active session file, readable from both isolates.
const kActiveRecordingKey = 'cairn.activeRecording';

/// Lifecycle of a session file.
abstract final class RecordingSessionStatus {
  /// Recording (or paused) with the service expected to run.
  static const active = 'active';

  /// Stopped from the notification while the app was not running: the next
  /// launch ingests the log into the library.
  static const stopped = 'stopped';
}

/// Everything the foreground task needs to run a recording on its own, written
/// by the main isolate before the service starts: identity, the route being
/// followed (with per-vertex DEM elevations), engine options, the power
/// profile, the terrain cache directory, the durable log path, and the
/// already-localized notification strings.
class RecordingSession {
  const RecordingSession({
    required this.trackId,
    required this.name,
    required this.startedAt,
    required this.logPath,
    required this.terrainDir,
    required this.options,
    required this.profile,
    required this.labels,
    required this.metric,
    this.packKg,
    this.followRouteId,
    this.followRouteName,
    this.route,
    this.routeElev,
    this.autoSaver = true,
    this.simulate = false,
    this.batteryStartPct,
    this.status = RecordingSessionStatus.active,
    this.endedAt,
  });

  final String trackId;
  final String name;
  final DateTime startedAt;
  final String logPath;
  final String terrainDir;
  final RecordingEngineOptions options;
  final RecordingProfile profile;

  /// Localized strings for the notification: title, body (with `{d}` and
  /// `{t}` placeholders), offRoute, paused, autoPaused, pause, resume, stop.
  final Map<String, String> labels;
  final bool metric;
  final double? packKg;
  final String? followRouteId;
  final String? followRouteName;
  final List<List<double>>? route;
  final List<double>? routeElev;

  /// Drop to the Saver profile below 20 percent battery.
  final bool autoSaver;

  /// Debug only: walk the route instead of reading the GPS.
  final bool simulate;
  final int? batteryStartPct;
  final String status;
  final DateTime? endedAt;

  RecordingSession copyWith({String? status, DateTime? endedAt}) =>
      RecordingSession(
        trackId: trackId,
        name: name,
        startedAt: startedAt,
        logPath: logPath,
        terrainDir: terrainDir,
        options: options,
        profile: profile,
        labels: labels,
        metric: metric,
        packKg: packKg,
        followRouteId: followRouteId,
        followRouteName: followRouteName,
        route: route,
        routeElev: routeElev,
        autoSaver: autoSaver,
        simulate: simulate,
        batteryStartPct: batteryStartPct,
        status: status ?? this.status,
        endedAt: endedAt ?? this.endedAt,
      );

  Map<String, dynamic> toJson() => {
        'v': 1,
        'trackId': trackId,
        'name': name,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'logPath': logPath,
        'terrainDir': terrainDir,
        'options': options.toJson(),
        'profile': profile.name,
        'labels': labels,
        'metric': metric,
        'packKg': packKg,
        'followRouteId': followRouteId,
        'followRouteName': followRouteName,
        'route': route,
        'routeElev': routeElev,
        'autoSaver': autoSaver,
        'simulate': simulate,
        'batteryStartPct': batteryStartPct,
        'status': status,
        'endedAt': endedAt?.millisecondsSinceEpoch,
      };

  static RecordingSession fromJson(Map<String, dynamic> m) {
    final route = m['route'] as List?;
    final elev = m['routeElev'] as List?;
    return RecordingSession(
      trackId: m['trackId'] as String,
      name: m['name'] as String,
      startedAt:
          DateTime.fromMillisecondsSinceEpoch((m['startedAt'] as num).toInt()),
      logPath: m['logPath'] as String,
      terrainDir: m['terrainDir'] as String,
      options: RecordingEngineOptions.fromJson(
          (m['options'] as Map?)?.cast<String, dynamic>() ?? const {}),
      profile: RecordingProfile.values.firstWhere(
        (v) => v.name == m['profile'],
        orElse: () => RecordingProfile.precise,
      ),
      labels: (m['labels'] as Map?)?.cast<String, String>() ?? const {},
      metric: m['metric'] as bool? ?? false,
      packKg: (m['packKg'] as num?)?.toDouble(),
      followRouteId: m['followRouteId'] as String?,
      followRouteName: m['followRouteName'] as String?,
      route: route == null
          ? null
          : [
              for (final pt in route)
                [(pt[0] as num).toDouble(), (pt[1] as num).toDouble()],
            ],
      routeElev:
          elev == null ? null : [for (final e in elev) (e as num).toDouble()],
      autoSaver: m['autoSaver'] as bool? ?? true,
      simulate: m['simulate'] as bool? ?? false,
      batteryStartPct: (m['batteryStartPct'] as num?)?.toInt(),
      status: m['status'] as String? ?? RecordingSessionStatus.active,
      endedAt: m['endedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((m['endedAt'] as num).toInt()),
    );
  }

  /// The session file for [trackId] under the app support directory.
  static File fileFor(Directory supportDir, String trackId) =>
      File(p.join(supportDir.path, 'recording', '$trackId.json'));

  /// The durable log next to the session file.
  static String logPathFor(Directory supportDir, String trackId) =>
      p.join(supportDir.path, 'recording', '$trackId.jsonl');

  static Future<RecordingSession?> read(File file) async {
    try {
      if (!await file.exists()) return null;
      final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return fromJson(m);
    } on Exception {
      return null;
    }
  }

  Future<void> write(File file) async {
    await file.parent.create(recursive: true);
    // Write-then-rename so a kill mid-write cannot leave a torn session file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(toJson()), flush: true);
    await tmp.rename(file.path);
  }

  /// Builds the engine this session describes.
  RecordingEngine newEngine() => RecordingEngine(
        startedAt: startedAt,
        options: options,
        route: route,
        routeElev: routeElev,
      );
}
