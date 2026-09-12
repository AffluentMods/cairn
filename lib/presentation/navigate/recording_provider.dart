// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo/elevation_stats.dart';
import '../../core/geo/haversine.dart';
import '../../core/platform/battery_level.dart';
import '../../core/platform/screen_wake.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/units/unit_formatter.dart';
import '../../core/worker/geo_worker.dart';
import '../../data/data_providers.dart';
import '../../data/recording/recording_log.dart';
import '../../data/recording/recording_session.dart';
import '../../domain/models/track.dart';
import '../../domain/usecases/recording_engine.dart';
import '../../domain/usecases/trip_calories.dart';
import '../../l10n/app_localizations.dart';
import '../saved/library_providers.dart' show libraryRefreshProvider;
import 'navigate_providers.dart';
import 'recording_service.dart';
import 'route_editor_provider.dart';

enum RecordingStatus { idle, recording, paused }

/// Localized strings the foreground task needs, resolved on the main isolate
/// where l10n lives, then carried in the session file.
class RecordingLabels {
  const RecordingLabels({
    required this.title,
    required this.body,
    required this.offRoute,
    required this.paused,
    required this.autoPaused,
    required this.pause,
    required this.resume,
    required this.stop,
    required this.defaultName,
  });

  factory RecordingLabels.fromL10n(AppLocalizations l10n) => RecordingLabels(
        title: l10n.recordNotificationTitle,
        body: l10n.recordNotificationBody('{d}', '{t}'),
        offRoute: l10n.recordOffRouteBy('{d}'),
        paused: l10n.recordPaused,
        autoPaused: l10n.recordAutoPaused,
        pause: l10n.recordPause,
        resume: l10n.recordResume,
        stop: l10n.recordNotificationStop,
        defaultName: l10n.recordDefaultName(
          DateFormat.yMMMd().add_jm().format(DateTime.now()),
        ),
      );

  final String title;
  final String body;
  final String offRoute;
  final String paused;
  final String autoPaused;
  final String pause;
  final String resume;
  final String stop;
  final String defaultName;

  Map<String, String> toMap() => {
        'title': title,
        'body': body,
        'offRoute': offRoute,
        'paused': paused,
        'autoPaused': autoPaused,
        'pause': pause,
        'resume': resume,
        'stop': stop,
      };
}

class RecordingState {
  const RecordingState({
    this.status = RecordingStatus.idle,
    this.snapshot,
    this.receivedAt,
    this.trackId,
    this.packKg,
    this.followRouteId,
    this.followRouteName,
    this.routeLengthM,
    this.profile,
    this.recovered = false,
    this.batteryRestricted = false,
    this.clock = 0,
    this.trackPoints = const [],
    this.trackVersion = 0,
    this.simulated = false,
  });

  final RecordingStatus status;

  /// The latest report from the recording service.
  final RecordingSnapshot? snapshot;

  /// When [snapshot] arrived, so the clock keeps ticking between reports.
  final DateTime? receivedAt;
  final String? trackId;
  final double? packKg;
  final String? followRouteId;
  final String? followRouteName;
  final double? routeLengthM;

  /// The GPS profile the service is currently running (it can drop to Saver
  /// on a low battery).
  final RecordingProfile? profile;

  /// The service died and the log was restored: paused until the hiker
  /// resumes or finishes.
  final bool recovered;

  /// Android battery optimization is on for Cairn, so the OS may stop the
  /// service in the background. Shown once per recording.
  final bool batteryRestricted;

  /// Bumped once a second while the app is visible so the clock repaints.
  final int clock;

  /// Every accepted fix so far as `[lat, lon]`, for the traveled-path layer
  /// (AllTrails draws it in a second color under the puck).
  final List<List<double>> trackPoints;

  /// Bumped whenever [trackPoints] changes, so the map redraws only then.
  final int trackVersion;

  /// Debug builds only: the fixes come from the route simulator, so the map
  /// draws its own puck at the simulated position instead of following the
  /// device location (Fix Pass 1 X2.8).
  final bool simulated;

  bool get isActive => status != RecordingStatus.idle;
  RecordingStats get stats => snapshot?.stats ?? RecordingStats.zero;
  bool get autoPaused => snapshot?.phase == RecordingPhase.autoPaused;
  bool get onRoute => snapshot?.onRoute ?? true;
  bool get routeKnown => snapshot?.routeKnown ?? false;
  bool get offRouteMuted => snapshot?.offRouteMuted ?? false;
  double? get offRouteDistanceM => snapshot?.offRouteDistanceM;
  double? get bearingBackDeg => snapshot?.bearingBackDeg;
  double? get distanceRemainingM => snapshot?.remainingM;
  double? get remainingGainM => snapshot?.remainingGainM;
  double? get progressM => snapshot?.progressM;
  double? get etaSeconds => snapshot?.etaSeconds;
  bool get arrived => snapshot?.arrived ?? false;
  double? get climbRemainingM => snapshot?.climbRemainingM;
  double? get climbGainLeftM => snapshot?.climbGainLeftM;
  double? get currentLat => snapshot?.lat;
  double? get currentLon => snapshot?.lon;
  double? get heading => snapshot?.heading;
  int get fixSeq => snapshot?.fixSeq ?? 0;

  /// Seconds since the last report, only while actively recording.
  int get _sinceReport {
    final at = receivedAt;
    if (at == null || snapshot?.phase != RecordingPhase.recording) return 0;
    final s = DateTime.now().difference(at).inSeconds;
    return s < 0 ? 0 : s;
  }

  /// Active time right now, advanced locally between service reports.
  int get totalSecondsNow => stats.totalSeconds + _sinceReport;

  int get elapsedSecondsNow => (snapshot?.elapsedSeconds ?? 0) + _sinceReport;

  RecordingState copyWith({
    RecordingStatus? status,
    RecordingSnapshot? snapshot,
    DateTime? receivedAt,
    String? trackId,
    double? packKg,
    String? followRouteId,
    String? followRouteName,
    double? routeLengthM,
    RecordingProfile? profile,
    bool? recovered,
    bool? batteryRestricted,
    int? clock,
    List<List<double>>? trackPoints,
    int? trackVersion,
    bool? simulated,
  }) {
    return RecordingState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      receivedAt: receivedAt ?? this.receivedAt,
      trackId: trackId ?? this.trackId,
      packKg: packKg ?? this.packKg,
      followRouteId: followRouteId ?? this.followRouteId,
      followRouteName: followRouteName ?? this.followRouteName,
      routeLengthM: routeLengthM ?? this.routeLengthM,
      profile: profile ?? this.profile,
      recovered: recovered ?? this.recovered,
      batteryRestricted: batteryRestricted ?? this.batteryRestricted,
      clock: clock ?? this.clock,
      trackPoints: trackPoints ?? this.trackPoints,
      trackVersion: trackVersion ?? this.trackVersion,
      simulated: simulated ?? this.simulated,
    );
  }
}

/// The main-isolate side of recording (spec Phase 6). Thin by design: it
/// writes the session file, starts the foreground service, mirrors the
/// service's snapshots into [RecordingState], forwards pause/resume/mute, and
/// ingests the durable log into the library on Finish. On launch it
/// re-attaches to a running service, recovers a session whose service died,
/// or ingests one that was stopped from the notification while the app was
/// gone.
class RecordingController extends Notifier<RecordingState> {
  Timer? _clock;
  RecordingSession? _session;
  AppLifecycleListener? _lifecycle;
  bool _visible = true;
  bool _busy = false;

  late final DataCallback _onData = _handleTaskData;

  @override
  RecordingState build() {
    FlutterForegroundTask.addTaskDataCallback(_onData);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _visible = true;
        _syncClock();
        if (state.isActive) _send({'cmd': RecordingCommand.snapshot});
      },
      onHide: () {
        _visible = false;
        _syncClock();
      },
    );
    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onData);
      _clock?.cancel();
      _lifecycle?.dispose();
    });
    return const RecordingState();
  }

  void _send(Map<String, Object?> cmd) =>
      FlutterForegroundTask.sendDataToTask(cmd);

  /// One repaint a second while a recording is visible; nothing while the app
  /// is in the background (Fix Pass 1 budgets, battery).
  void _syncClock() {
    final want = _visible && state.isActive;
    if (want && _clock == null) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.snapshot?.phase == RecordingPhase.recording) {
          state = state.copyWith(clock: state.clock + 1);
        }
      });
    } else if (!want) {
      _clock?.cancel();
      _clock = null;
    }
  }

  void _handleTaskData(Object data) {
    if (data is! String) return;
    Map<String, dynamic> m;
    try {
      m = jsonDecode(data) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    switch (m['type']) {
      case RecordingMessage.snapshot:
        final snap =
            RecordingSnapshot.fromJson(m['data'] as Map<String, dynamic>);
        RecordingProfile? profile;
        for (final p in RecordingProfile.values) {
          if (p.name == m['profile']) profile = p;
        }
        _applySnapshot(snap, profile);
      case RecordingMessage.polyline:
        if (!state.isActive) return;
        final data = m['data'] as List? ?? const [];
        state = state.copyWith(
          trackPoints: [
            for (final p in data)
              [(p[0] as num).toDouble(), (p[1] as num).toDouble()],
          ],
          trackVersion: state.trackVersion + 1,
        );
      case RecordingMessage.stop:
        unawaited(finish());
    }
  }

  void _applySnapshot(RecordingSnapshot snap, RecordingProfile? profile) {
    if (!state.isActive) return;
    // A new accepted fix extends the traveled path.
    var points = state.trackPoints;
    var version = state.trackVersion;
    if (snap.fixSeq > state.fixSeq && snap.lat != null && snap.lon != null) {
      points = [
        ...points,
        [snap.lat!, snap.lon!]
      ];
      version++;
    }
    state = state.copyWith(
      status: snap.phase == RecordingPhase.recording
          ? RecordingStatus.recording
          : RecordingStatus.paused,
      snapshot: snap,
      receivedAt: DateTime.now(),
      profile: profile,
      recovered: false,
      trackPoints: points,
      trackVersion: version,
    );
    for (final e in snap.events) {
      switch (e) {
        case 'offRoute':
          // Two heavy taps: distinct from every other haptic in the app.
          unawaited(HapticFeedback.heavyImpact().then((_) =>
              Future<void>.delayed(const Duration(milliseconds: 180),
                  HapticFeedback.heavyImpact)));
        case 'arrived':
          unawaited(HapticFeedback.mediumImpact());
      }
    }
  }

  Future<bool> start({
    required RecordingLabels labels,
    double? packKg,
    String? followRouteId,
  }) async {
    if (state.isActive || _busy) return true;
    _busy = true;
    try {
      await Permission.locationWhenInUse.request();
      await Permission.locationAlways.request();
      await Permission.notification.request();

      final settings = ref.read(settingsProvider);
      final supportDir = ref.read(appSupportDirProvider);
      final id = const Uuid().v4();
      final now = DateTime.now();

      List<List<double>>? route;
      String? routeName;
      if (followRouteId != null) {
        final saved =
            await ref.read(routeRepositoryProvider).byId(followRouteId);
        if (saved != null) {
          route = saved.geometry;
          routeName = saved.name;
        }
      }
      // Fall back to the route loaded in Navigate, so "Navigate this trail"
      // tracks on-route, distance remaining, and the ETA (Fix Pass 1 X2.6).
      if (route == null) {
        final active = ref.read(routeEditorProvider).polyline;
        if (active.length >= 2) {
          route = active;
          routeName = ref.read(activeRouteNameProvider);
        }
      }
      List<double>? routeElev;
      if (route != null) {
        try {
          routeElev = await ref
              .read(elevationRepositoryProvider)
              .elevationsAlong(route);
        } on Exception {
          routeElev = null;
        }
      }

      final batteryStart = await readBatteryPercent();
      final session = RecordingSession(
        trackId: id,
        name: labels.defaultName,
        startedAt: now,
        logPath: RecordingSession.logPathFor(supportDir, id),
        terrainDir: '${supportDir.path}${Platform.pathSeparator}terrain',
        options: RecordingEngineOptions(autoPause: settings.autoPause),
        profile: settings.recordingProfile,
        labels: labels.toMap(),
        metric: settings.units == UnitSystem.metric,
        packKg: packKg,
        followRouteId: followRouteId,
        followRouteName: routeName,
        route: route,
        routeElev: routeElev,
        autoSaver: settings.autoSaver,
        simulate: kDebugMode && ref.read(simulateLocationProvider),
        batteryStartPct: batteryStart,
      );
      final file = RecordingSession.fileFor(supportDir, id);
      await session.write(file);
      await FlutterForegroundTask.saveData(
          key: kActiveRecordingKey, value: file.path);
      _session = session;

      await ref.read(trackRepositoryProvider).createTrack(
            TrackSummary(
              id: id,
              name: session.name,
              startedAt: now,
              packWeightKg: packKg,
              linkedRouteId: followRouteId,
              batteryStartPct: batteryStart,
            ),
          );

      final started = await _startService(session);
      if (!started) {
        await _clearSessionFiles(session);
        _session = null;
        return false;
      }

      var restricted = false;
      if (Platform.isAndroid) {
        try {
          restricted =
              !(await FlutterForegroundTask.isIgnoringBatteryOptimizations);
        } on Exception {
          restricted = false;
        }
      }
      if (settings.keepScreenOn) await ScreenWake.keepOn(true);

      state = RecordingState(
        status: RecordingStatus.recording,
        trackId: id,
        packKg: packKg,
        followRouteId: followRouteId,
        followRouteName: routeName,
        routeLengthM: route == null ? null : polylineLengthMeters(route),
        profile: settings.recordingProfile,
        batteryRestricted: restricted,
        receivedAt: now,
        simulated: session.simulate,
      );
      _syncClock();
      return true;
    } finally {
      _busy = false;
    }
  }

  Future<bool> _startService(RecordingSession session) async {
    final labels = session.labels;
    initRecordingService(channelName: labels['title'] ?? 'Recording');
    return startRecordingService(
      title: labels['title'] ?? 'Recording',
      text: session.name,
      pauseLabel: labels['pause'] ?? 'Pause',
      stopLabel: labels['stop'] ?? 'Stop',
    );
  }

  void pause() {
    if (state.status != RecordingStatus.recording) return;
    state = state.copyWith(status: RecordingStatus.paused);
    _send({'cmd': RecordingCommand.pause});
  }

  Future<void> resume() async {
    if (state.status != RecordingStatus.paused) return;
    final session = _session;
    if (state.recovered && session != null) {
      // The service died: log the resume so the gap counts as a pause, then
      // start a fresh service that replays the log and carries on.
      final line =
          jsonEncode({'e': 'r', 't': DateTime.now().millisecondsSinceEpoch});
      final log = RecordingLogWriter(File(session.logPath));
      await log.open();
      await log.append([line]);
      await log.close();
      final ok = await _startService(session);
      if (!ok) return;
      state =
          state.copyWith(status: RecordingStatus.recording, recovered: false);
      _syncClock();
      return;
    }
    state = state.copyWith(status: RecordingStatus.recording);
    _send({'cmd': RecordingCommand.resume});
  }

  /// Silences the off-route alert until the hiker is back on the trail.
  void muteOffRoute() => _send({'cmd': RecordingCommand.mute});

  void setProfile(RecordingProfile profile) {
    state = state.copyWith(profile: profile);
    _send({'cmd': RecordingCommand.profile, 'value': profile.name});
  }

  /// Once the hint has been seen.
  void dismissBatteryHint() => state = state.copyWith(batteryRestricted: false);

  /// Opens Android's battery optimization page for Cairn.
  Future<void> openBatterySettings() async {
    dismissBatteryHint();
    try {
      await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    } on Exception {
      // not Android
    }
  }

  Future<TrackSummary?> finish() async {
    final session = _session;
    if (session == null || _busy) return null;
    _busy = true;
    try {
      _clock?.cancel();
      _clock = null;
      await ScreenWake.keepOn(false);
      await stopRecordingService(); // onDestroy flushes and closes the log
      final summary = await _ingest(session);
      _session = null;
      state = const RecordingState();
      return summary;
    } finally {
      _busy = false;
    }
  }

  Future<void> discard() async {
    final session = _session;
    _clock?.cancel();
    _clock = null;
    await ScreenWake.keepOn(false);
    await stopRecordingService();
    if (session != null) {
      await ref.read(trackRepositoryProvider).deleteTrack(session.trackId);
      await _clearSessionFiles(session);
    }
    _session = null;
    state = const RecordingState();
  }

  /// Reads the durable log, refines elevations with the DEM, computes the
  /// summary and calories, and saves the track in one transaction.
  Future<TrackSummary?> _ingest(RecordingSession session) async {
    final logFile = File(session.logPath);
    final lines =
        await logFile.exists() ? await logFile.readAsLines() : <String>[];
    final endedAt = session.endedAt ?? DateTime.now();
    final replayed = await GeoWorker.run(
      'recording-ingest',
      () => replayForIngest(session, lines, endedAt),
    );
    final points = replayed.points;

    // Refine elevations with the DEM now that we may be back online; where a
    // tile is still missing keep the engine's value (GPS median).
    final latLon = [
      for (final p in points) [p.lat, p.lon],
    ];
    List<double?> dem = const [];
    try {
      dem = await ref.read(terrainTileSourceProvider).elevations(latLon);
    } on Exception {
      dem = List<double?>.filled(points.length, null);
    }
    final complete = dem.isNotEmpty && !dem.contains(null);
    var gain = replayed.stats.gainM;
    var loss = replayed.stats.lossM;
    if (complete) {
      final gl = gainLoss([for (final d in dem) d!]);
      gain = gl.gain;
      loss = gl.loss;
    }

    final trackPoints = <TrackPointData>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      trackPoints.add(TrackPointData(
        seq: p.seq,
        t: p.t,
        lat: p.lat,
        lon: p.lon,
        gpsAltM: p.gpsAltM,
        demAltM: (i < dem.length ? dem[i] : null) ?? p.demAltM,
        accuracyM: p.accuracyM,
        speedMps: p.speedMps,
      ));
    }

    final segments = <CalorieSegment>[];
    for (var i = 1; i < trackPoints.length; i++) {
      final a = trackPoints[i - 1];
      final b = trackPoints[i];
      final dist = haversineMeters(a.lat, a.lon, b.lat, b.lon);
      final seconds = b.t.difference(a.t).inSeconds.toDouble();
      final dh = (b.elevM ?? 0) - (a.elevM ?? 0);
      segments.add(
          CalorieSegment(distanceM: dist, elevDeltaM: dh, seconds: seconds));
    }
    final bodyKg = ref.read(settingsProvider).bodyWeightKg ?? kDefaultBodyKg;
    final calories = tripCaloriesKcal(
      bodyKg: bodyKg,
      packKg: session.packKg ?? 0,
      segments: segments,
    );

    // The end battery is only meaningful if we are finishing now.
    int? batteryEnd;
    if (DateTime.now().difference(endedAt).inMinutes < 10) {
      batteryEnd = await readBatteryPercent();
    }

    final repo = ref.read(trackRepositoryProvider);
    final existing = await repo.trackById(session.trackId);
    final summary = TrackSummary(
      id: session.trackId,
      name: existing?.name ?? session.name,
      startedAt: session.startedAt,
      endedAt: endedAt,
      distanceM: replayed.stats.distanceM,
      movingSeconds: replayed.stats.movingSeconds,
      totalSeconds: replayed.stats.totalSeconds,
      gainM: gain,
      lossM: loss,
      packWeightKg: session.packKg,
      calories: calories,
      linkedRouteId: session.followRouteId,
      batteryStartPct: session.batteryStartPct,
      batteryEndPct: batteryEnd,
    );
    await repo.saveTrack(summary, trackPoints);
    await _clearSessionFiles(session);
    ref.read(libraryRefreshProvider.notifier).state++;
    return summary;
  }

  Future<void> _clearSessionFiles(RecordingSession session) async {
    final supportDir = ref.read(appSupportDirProvider);
    for (final f in [
      RecordingSession.fileFor(supportDir, session.trackId),
      File(session.logPath),
    ]) {
      try {
        if (await f.exists()) await f.delete();
      } on FileSystemException {
        // ignore
      }
    }
    await FlutterForegroundTask.removeData(key: kActiveRecordingKey);
  }

  /// Called once at app start. Re-attaches to a running service, ingests a
  /// session stopped from the notification while the app was gone, or
  /// recovers (as paused) a session whose service died.
  Future<void> attachOnLaunch() async {
    if (state.isActive) return;
    final path =
        await FlutterForegroundTask.getData<String>(key: kActiveRecordingKey);
    if (path == null) return;
    final session = await RecordingSession.read(File(path));
    if (session == null) {
      await FlutterForegroundTask.removeData(key: kActiveRecordingKey);
      return;
    }
    _session = session;

    if (session.status == RecordingSessionStatus.stopped) {
      await _ingest(session);
      _session = null;
      return;
    }

    _loadRouteIfNeeded(session);
    final running = await FlutterForegroundTask.isRunningService;
    final base = RecordingState(
      status: RecordingStatus.paused,
      trackId: session.trackId,
      packKg: session.packKg,
      followRouteId: session.followRouteId,
      followRouteName: session.followRouteName,
      routeLengthM:
          session.route == null ? null : polylineLengthMeters(session.route!),
      profile: session.profile,
      receivedAt: DateTime.now(),
      simulated: kDebugMode && session.simulate,
    );
    if (running) {
      state = base.copyWith(status: RecordingStatus.recording);
      _send({'cmd': RecordingCommand.snapshot});
      _send({'cmd': RecordingCommand.polyline});
    } else {
      // The service died with the app. Treat the gap as a pause, starting at
      // the log's last write (the best estimate of when it stopped).
      final logFile = File(session.logPath);
      var pausedAt = DateTime.now();
      if (await logFile.exists()) pausedAt = await logFile.lastModified();
      final log = RecordingLogWriter(logFile);
      await log.open();
      await log.append([
        jsonEncode({'e': 'p', 't': pausedAt.millisecondsSinceEpoch})
      ]);
      await log.close();
      final lines = await logFile.readAsLines();
      final recovered = await GeoWorker.run(
        'recording-recover',
        () => snapshotAfterReplay(session, lines, DateTime.now()),
      );
      state = base.copyWith(
        snapshot: recovered.snapshot,
        recovered: true,
        trackPoints: recovered.points,
        trackVersion: 1,
      );
    }
    _syncClock();
    if (ref.read(settingsProvider).keepScreenOn && running) {
      await ScreenWake.keepOn(true);
    }
    appRouter.go('/navigate');
  }

  void _loadRouteIfNeeded(RecordingSession session) {
    final route = session.route;
    if (route == null || route.length < 2) return;
    if (ref.read(routeEditorProvider).polyline.length >= 2) return;
    unawaited(ref.read(routeEditorProvider.notifier).loadPolyline(route));
    ref.read(activeRouteNameProvider.notifier).state = session.followRouteName;
  }
}

/// Replays a session's log for ingest. Top-level and pure so it can run in a
/// worker isolate.
({List<EnginePoint> points, RecordingStats stats}) replayForIngest(
  RecordingSession session,
  List<String> lines,
  DateTime endedAt,
) {
  final engine = session.newEngine();
  replayRecordingLines(lines, engine);
  return (points: engine.points, stats: engine.stats(endedAt));
}

/// Replays a session's log and reports the state and the path so far, for
/// recovery on launch.
({RecordingSnapshot snapshot, List<List<double>> points}) snapshotAfterReplay(
  RecordingSession session,
  List<String> lines,
  DateTime now,
) {
  final engine = session.newEngine();
  replayRecordingLines(lines, engine);
  return (
    snapshot: engine.snapshot(now),
    points: [
      for (final p in engine.points) [p.lat, p.lon],
    ],
  );
}

final recordingProvider = NotifierProvider<RecordingController, RecordingState>(
  RecordingController.new,
);
