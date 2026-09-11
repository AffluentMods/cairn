// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo/elevation_stats.dart';
import '../../core/geo/haversine.dart';
import '../../core/geo/nearest_point.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../domain/models/track.dart';
import '../../domain/usecases/recording_accumulator.dart';
import '../../domain/usecases/trip_calories.dart';
import '../saved/library_providers.dart' show libraryRefreshProvider;
import 'recording_service.dart';

enum RecordingStatus { idle, recording, paused }

class RecordingState {
  const RecordingState({
    this.status = RecordingStatus.idle,
    this.stats = RecordingStats.zero,
    this.trackId,
    this.packKg,
    this.followRouteId,
    this.followRouteName,
    this.distanceRemainingM,
    this.onRoute = true,
    this.currentLat,
    this.currentLon,
    this.heading,
    this.fixSeq = 0,
  });

  final RecordingStatus status;
  final RecordingStats stats;
  final String? trackId;
  final double? packKg;
  final String? followRouteId;
  final String? followRouteName;
  final double? distanceRemainingM;
  final bool onRoute;

  /// The latest accepted fix, so the map can follow it (Fix Pass 1 X2.6).
  final double? currentLat;
  final double? currentLon;

  /// Course over ground in degrees, or null when unknown (stationary).
  final double? heading;

  /// Bumped on every accepted fix, so a follow listener fires even when the
  /// coordinates round to the same value.
  final int fixSeq;

  bool get isActive => status != RecordingStatus.idle;

  RecordingState copyWith({
    RecordingStatus? status,
    RecordingStats? stats,
    String? trackId,
    double? packKg,
    String? followRouteId,
    String? followRouteName,
    double? distanceRemainingM,
    bool? onRoute,
    double? currentLat,
    double? currentLon,
    double? heading,
    int? fixSeq,
  }) {
    return RecordingState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      trackId: trackId ?? this.trackId,
      packKg: packKg ?? this.packKg,
      followRouteId: followRouteId ?? this.followRouteId,
      followRouteName: followRouteName ?? this.followRouteName,
      distanceRemainingM: distanceRemainingM ?? this.distanceRemainingM,
      onRoute: onRoute ?? this.onRoute,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      heading: heading ?? this.heading,
      fixSeq: fixSeq ?? this.fixSeq,
    );
  }
}

class RecordingController extends Notifier<RecordingState> {
  StreamSubscription<Position>? _sub;
  Timer? _ticker;
  RecordingAccumulator? _acc;
  Duration _paused = Duration.zero;
  DateTime? _pauseStart;
  int _seq = 0;
  int _lastNotify = 0;
  List<List<double>>? _routeGeom;
  double? _routeLenM;
  double? _curLat;
  double? _curLon;
  double? _curHeading;
  int _fixSeq = 0;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _ticker?.cancel();
    });
    return const RecordingState();
  }

  Future<bool> start({double? packKg, String? followRouteId}) async {
    if (state.isActive) return true;
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    await Permission.notification.request();

    final id = const Uuid().v4();
    final now = DateTime.now();
    final name = 'Hike ${DateFormat.yMMMd().add_jm().format(now)}';
    final trackRepo = ref.read(trackRepositoryProvider);
    await trackRepo.createTrack(
      TrackSummary(id: id, name: name, startedAt: now, packWeightKg: packKg),
    );

    String? routeName;
    if (followRouteId != null) {
      final route = await ref.read(routeRepositoryProvider).byId(followRouteId);
      if (route != null) {
        _routeGeom = route.geometry;
        _routeLenM = route.distanceM;
        routeName = route.name;
      }
    }

    _acc = RecordingAccumulator();
    _seq = 0;
    _paused = Duration.zero;
    _pauseStart = null;
    _lastNotify = 0;

    initRecordingService();
    await startRecordingService('Recording', name);

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    state = RecordingState(
      status: RecordingStatus.recording,
      trackId: id,
      packKg: packKg,
      followRouteId: followRouteId,
      followRouteName: routeName,
    );
    return true;
  }

  void _onPosition(Position pos) {
    if (state.status != RecordingStatus.recording) return;
    final acc = _acc;
    final trackId = state.trackId;
    if (acc == null || trackId == null) return;

    final sample = RecordingSample(
      t: pos.timestamp,
      lat: pos.latitude,
      lon: pos.longitude,
      accuracyM: pos.accuracy,
      speedMps: pos.speed,
      elevM: pos.altitude,
    );
    if (!acc.add(sample)) return;

    _curLat = pos.latitude;
    _curLon = pos.longitude;
    // geolocator reports heading < 0 or 0 when stationary; keep the last known.
    if (pos.heading > 0 && pos.speed > 0.5) _curHeading = pos.heading;
    _fixSeq++;

    ref.read(trackRepositoryProvider).appendPoint(
          trackId,
          TrackPointData(
            seq: _seq++,
            t: pos.timestamp,
            lat: pos.latitude,
            lon: pos.longitude,
            gpsAltM: pos.altitude,
            accuracyM: pos.accuracy,
            speedMps: pos.speed,
          ),
        );
    _updateState();
  }

  void _tick() {
    if (state.status == RecordingStatus.recording) _updateState();
  }

  RecordingStats _statsNow() {
    final acc = _acc;
    if (acc == null) return RecordingStats.zero;
    final raw = acc.statsAt(DateTime.now());
    final pausedNow = _pauseStart != null
        ? DateTime.now().difference(_pauseStart!)
        : Duration.zero;
    final total = (raw.totalSeconds - _paused.inSeconds - pausedNow.inSeconds)
        .clamp(0, 1 << 31);
    return RecordingStats(
      distanceM: raw.distanceM,
      movingSeconds: raw.movingSeconds,
      totalSeconds: total,
      gainM: raw.gainM,
      lossM: raw.lossM,
      currentSpeedMps: raw.currentSpeedMps,
      currentElevM: raw.currentElevM,
      pointCount: raw.pointCount,
    );
  }

  void _updateState() {
    final stats = _statsNow();
    var onRoute = state.onRoute;
    var remaining = state.distanceRemainingM;
    final geom = _routeGeom;
    final poly = _acc?.polyline;
    if (geom != null && poly != null && poly.isNotEmpty) {
      final last = poly.last;
      final np = nearestPointOnPolyline(last[0], last[1], geom);
      if (np != null) {
        onRoute = np.distanceM <= 60;
        remaining = (_routeLenM ?? 0) - _progressAlong(geom, np);
        if (remaining < 0) remaining = 0;
      }
    }
    state = state.copyWith(
      stats: stats,
      onRoute: onRoute,
      distanceRemainingM: remaining,
      currentLat: _curLat,
      currentLon: _curLon,
      heading: _curHeading,
      fixSeq: _fixSeq,
    );

    final nowSec = stats.totalSeconds;
    if (nowSec - _lastNotify >= 15) {
      _lastNotify = nowSec;
      final fmt = ref.read(unitFormatterProvider);
      updateRecordingNotification(
        'Recording',
        '${fmt.distance(stats.distanceM)}, ${UnitFormatter.durationClock(Duration(seconds: nowSec))}',
      );
    }
  }

  double _progressAlong(List<List<double>> geom, NearestPoint np) {
    var d = 0.0;
    for (var i = 0; i < np.segmentIndex && i < geom.length - 1; i++) {
      d += haversineMeters(
          geom[i][0], geom[i][1], geom[i + 1][0], geom[i + 1][1]);
    }
    return d;
  }

  void pause() {
    if (state.status != RecordingStatus.recording) return;
    _pauseStart = DateTime.now();
    state = state.copyWith(status: RecordingStatus.paused);
  }

  void resume() {
    if (state.status != RecordingStatus.paused) return;
    if (_pauseStart != null) {
      _paused += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }
    state = state.copyWith(status: RecordingStatus.recording);
  }

  Future<TrackSummary?> finish() async {
    final trackId = state.trackId;
    if (trackId == null) return null;
    await _teardown();

    final trackRepo = ref.read(trackRepositoryProvider);
    final track = await trackRepo.trackById(trackId);
    if (track == null) return null;
    final points = await trackRepo.pointsFor(trackId);

    // Refine gain/loss with DEM and estimate calories.
    final geometry = [
      for (final p in points) [p.lat, p.lon],
    ];
    final dem =
        await ref.read(elevationRepositoryProvider).elevationsAlong(geometry);
    final gl = gainLoss(dem);

    final segments = <CalorieSegment>[];
    for (var i = 1; i < points.length; i++) {
      final dist = haversineMeters(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
      final seconds =
          points[i].t.difference(points[i - 1].t).inSeconds.toDouble();
      final dh = (i < dem.length ? dem[i] : 0.0) -
          (i - 1 < dem.length ? dem[i - 1] : 0.0);
      segments.add(
        CalorieSegment(distanceM: dist, elevDeltaM: dh, seconds: seconds),
      );
    }
    final bodyKg = ref.read(settingsProvider).bodyWeightKg ?? kDefaultBodyKg;
    final calories = tripCaloriesKcal(
      bodyKg: bodyKg,
      packKg: track.packWeightKg ?? 0,
      segments: segments,
    );

    final stats = _statsNow();
    final finished = track.copyWith(
      endedAt: DateTime.now(),
      distanceM: stats.distanceM,
      movingSeconds: stats.movingSeconds,
      totalSeconds: stats.totalSeconds,
      gainM: gl.gain,
      lossM: gl.loss,
      calories: calories,
    );
    await trackRepo.updateSummary(finished);
    ref.read(libraryRefreshProvider.notifier).state++;

    _acc = null;
    state = const RecordingState();
    return finished;
  }

  Future<void> discard() async {
    final trackId = state.trackId;
    await _teardown();
    if (trackId != null) {
      await ref.read(trackRepositoryProvider).deleteTrack(trackId);
    }
    _acc = null;
    state = const RecordingState();
  }

  Future<void> _teardown() async {
    await _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    await stopRecordingService();
  }
}

final recordingProvider = NotifierProvider<RecordingController, RecordingState>(
  RecordingController.new,
);
