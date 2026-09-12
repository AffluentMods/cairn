// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import '../../core/geo/elevation_stats.dart';
import '../../core/geo/haversine.dart';
import '../../core/geo/nearest_point.dart';
import 'climbs.dart';

/// The power profile a recording runs with (Settings > Recording). Precise is
/// GPS-only at 5 m; Balanced uses the fused provider at 10 m every 4 s; Saver
/// batches at 30 m every 15 s so the radio wakes less often.
enum RecordingProfile { precise, balanced, saver }

/// One GPS fix handed to the engine.
class RecordingSample {
  const RecordingSample({
    required this.t,
    required this.lat,
    required this.lon,
    this.accuracyM,
    this.speedMps,
    this.elevM,
  });
  final DateTime t;
  final double lat;
  final double lon;
  final double? accuracyM;
  final double? speedMps;
  final double? elevM;
}

/// Live recording statistics.
class RecordingStats {
  const RecordingStats({
    required this.distanceM,
    required this.movingSeconds,
    required this.totalSeconds,
    required this.gainM,
    required this.lossM,
    required this.currentSpeedMps,
    required this.currentElevM,
    required this.pointCount,
  });

  final double distanceM;
  final int movingSeconds;

  /// Active time: elapsed minus every pause, manual or automatic.
  final int totalSeconds;
  final double gainM;
  final double lossM;
  final double currentSpeedMps;
  final double? currentElevM;
  final int pointCount;

  static const zero = RecordingStats(
    distanceM: 0,
    movingSeconds: 0,
    totalSeconds: 0,
    gainM: 0,
    lossM: 0,
    currentSpeedMps: 0,
    currentElevM: null,
    pointCount: 0,
  );

  Map<String, dynamic> toJson() => {
        'd': distanceM,
        'mv': movingSeconds,
        'tt': totalSeconds,
        'g': gainM,
        'l': lossM,
        'sp': currentSpeedMps,
        'el': currentElevM,
        'n': pointCount,
      };

  static RecordingStats fromJson(Map<String, dynamic> m) => RecordingStats(
        distanceM: (m['d'] as num).toDouble(),
        movingSeconds: (m['mv'] as num).toInt(),
        totalSeconds: (m['tt'] as num).toInt(),
        gainM: (m['g'] as num).toDouble(),
        lossM: (m['l'] as num).toDouble(),
        currentSpeedMps: (m['sp'] as num).toDouble(),
        currentElevM: (m['el'] as num?)?.toDouble(),
        pointCount: (m['n'] as num).toInt(),
      );
}

/// Where the engine is in its pause state machine.
enum RecordingPhase { recording, paused, autoPaused }

/// Tunables for the recording engine. Defaults follow spec Phase 6 (30 m
/// accuracy gate, 12 m/s jump gate, 0.5 m/s moving threshold, 5 m gain
/// hysteresis, auto-pause within 20 s, 60 m off route for 30 s).
class RecordingEngineOptions {
  const RecordingEngineOptions({
    this.maxAccuracyM = 30,
    this.maxSpeedMps = 12,
    this.movingThresholdMps = 0.5,
    this.gainThresholdM = 5,
    this.autoPause = true,
    this.autoPauseAfterS = 20,
    this.autoResumeSpeedMps = 0.8,
    this.autoResumeFixes = 2,
    this.offRouteM = 60,
    this.onRouteM = 30,
    this.offRouteDwellS = 30,
    this.offRouteMaxAccuracyM = 25,
    this.arriveWithinM = 30,
  });

  final double maxAccuracyM;
  final double maxSpeedMps;
  final double movingThresholdMps;
  final double gainThresholdM;
  final bool autoPause;
  final int autoPauseAfterS;
  final double autoResumeSpeedMps;
  final int autoResumeFixes;

  /// Enter the off-route state beyond this distance (spec: 60 m)...
  final double offRouteM;

  /// ...and leave it only back within this distance (hysteresis).
  final double onRouteM;

  /// The off-route distance must persist this long before the alert (spec: 30 s).
  final int offRouteDwellS;

  /// Fixes worse than this cannot start or extend an off-route dwell: a poor
  /// fix in a canyon must not fire a false alert.
  final double offRouteMaxAccuracyM;

  /// Arrival: within this distance of the route end after covering 90 percent.
  final double arriveWithinM;

  Map<String, dynamic> toJson() => {
        'maxAccuracyM': maxAccuracyM,
        'maxSpeedMps': maxSpeedMps,
        'movingThresholdMps': movingThresholdMps,
        'gainThresholdM': gainThresholdM,
        'autoPause': autoPause,
        'autoPauseAfterS': autoPauseAfterS,
        'autoResumeSpeedMps': autoResumeSpeedMps,
        'autoResumeFixes': autoResumeFixes,
        'offRouteM': offRouteM,
        'onRouteM': onRouteM,
        'offRouteDwellS': offRouteDwellS,
        'offRouteMaxAccuracyM': offRouteMaxAccuracyM,
        'arriveWithinM': arriveWithinM,
      };

  static RecordingEngineOptions fromJson(Map<String, dynamic> m) {
    const d = RecordingEngineOptions();
    double dbl(String k, double fallback) =>
        (m[k] as num?)?.toDouble() ?? fallback;
    int int_(String k, int fallback) => (m[k] as num?)?.toInt() ?? fallback;
    return RecordingEngineOptions(
      maxAccuracyM: dbl('maxAccuracyM', d.maxAccuracyM),
      maxSpeedMps: dbl('maxSpeedMps', d.maxSpeedMps),
      movingThresholdMps: dbl('movingThresholdMps', d.movingThresholdMps),
      gainThresholdM: dbl('gainThresholdM', d.gainThresholdM),
      autoPause: m['autoPause'] as bool? ?? d.autoPause,
      autoPauseAfterS: int_('autoPauseAfterS', d.autoPauseAfterS),
      autoResumeSpeedMps: dbl('autoResumeSpeedMps', d.autoResumeSpeedMps),
      autoResumeFixes: int_('autoResumeFixes', d.autoResumeFixes),
      offRouteM: dbl('offRouteM', d.offRouteM),
      onRouteM: dbl('onRouteM', d.onRouteM),
      offRouteDwellS: int_('offRouteDwellS', d.offRouteDwellS),
      offRouteMaxAccuracyM: dbl('offRouteMaxAccuracyM', d.offRouteMaxAccuracyM),
      arriveWithinM: dbl('arriveWithinM', d.arriveWithinM),
    );
  }
}

/// One accepted fix as the engine keeps it, and as the durable log stores it.
class EnginePoint {
  const EnginePoint({
    required this.seq,
    required this.tMs,
    required this.lat,
    required this.lon,
    this.gpsAltM,
    this.demAltM,
    this.accuracyM,
    this.speedMps,
  });

  final int seq;
  final int tMs;
  final double lat;
  final double lon;
  final double? gpsAltM;
  final double? demAltM;
  final double? accuracyM;
  final double? speedMps;

  DateTime get t => DateTime.fromMillisecondsSinceEpoch(tMs);

  List<Object?> toLogList() =>
      [seq, tMs, lat, lon, gpsAltM, demAltM, accuracyM, speedMps];

  static EnginePoint fromLogList(List<dynamic> l) => EnginePoint(
        seq: (l[0] as num).toInt(),
        tMs: (l[1] as num).toInt(),
        lat: (l[2] as num).toDouble(),
        lon: (l[3] as num).toDouble(),
        gpsAltM: (l[4] as num?)?.toDouble(),
        demAltM: (l[5] as num?)?.toDouble(),
        accuracyM: (l[6] as num?)?.toDouble(),
        speedMps: (l[7] as num?)?.toDouble(),
      );
}

/// What the engine reports after each fix or tick: everything the Navigate
/// sheet, the notification, and the map need. Serializable so the foreground
/// task handler can send it to the main isolate.
class RecordingSnapshot {
  const RecordingSnapshot({
    required this.phase,
    required this.stats,
    required this.elapsedSeconds,
    required this.fixSeq,
    this.lat,
    this.lon,
    this.heading,
    this.onRoute = true,
    this.routeKnown = false,
    this.offRouteDistanceM,
    this.bearingBackDeg,
    this.offRouteMuted = false,
    this.progressM,
    this.remainingM,
    this.remainingGainM,
    this.etaSeconds,
    this.arrived = false,
    this.climbRemainingM,
    this.climbGainLeftM,
    this.events = const [],
  });

  final RecordingPhase phase;
  final RecordingStats stats;
  final int elapsedSeconds;
  final int fixSeq;
  final double? lat;
  final double? lon;
  final double? heading;
  final bool onRoute;

  /// False until a fix good enough to judge the route has been projected;
  /// the UI shows nothing rather than a confident "On route" from a poor fix.
  final bool routeKnown;
  final double? offRouteDistanceM;
  final double? bearingBackDeg;
  final bool offRouteMuted;
  final double? progressM;
  final double? remainingM;
  final double? remainingGainM;
  final double? etaSeconds;
  final bool arrived;

  /// Inside a sustained climb on the route: distance and gain left to its
  /// top (the climb pill); null between climbs or without a route profile.
  final double? climbRemainingM;
  final double? climbGainLeftM;

  /// One-shot events since the previous snapshot: offRoute, arrived, paused,
  /// resumed, autoPaused, autoResumed.
  final List<String> events;

  Map<String, dynamic> toJson() => {
        'ph': phase.index,
        'st': stats.toJson(),
        'els': elapsedSeconds,
        'fs': fixSeq,
        'lat': lat,
        'lon': lon,
        'hd': heading,
        'on': onRoute,
        'rk': routeKnown,
        'off': offRouteDistanceM,
        'bb': bearingBackDeg,
        'mu': offRouteMuted,
        'pr': progressM,
        'rem': remainingM,
        'rg': remainingGainM,
        'eta': etaSeconds,
        'arr': arrived,
        'cr': climbRemainingM,
        'cg': climbGainLeftM,
        'ev': events,
      };

  static RecordingSnapshot fromJson(Map<String, dynamic> m) =>
      RecordingSnapshot(
        phase: RecordingPhase.values[(m['ph'] as num).toInt()],
        stats: RecordingStats.fromJson(m['st'] as Map<String, dynamic>),
        elapsedSeconds: (m['els'] as num).toInt(),
        fixSeq: (m['fs'] as num).toInt(),
        lat: (m['lat'] as num?)?.toDouble(),
        lon: (m['lon'] as num?)?.toDouble(),
        heading: (m['hd'] as num?)?.toDouble(),
        onRoute: m['on'] as bool? ?? true,
        routeKnown: m['rk'] as bool? ?? false,
        offRouteDistanceM: (m['off'] as num?)?.toDouble(),
        bearingBackDeg: (m['bb'] as num?)?.toDouble(),
        offRouteMuted: m['mu'] as bool? ?? false,
        progressM: (m['pr'] as num?)?.toDouble(),
        remainingM: (m['rem'] as num?)?.toDouble(),
        remainingGainM: (m['rg'] as num?)?.toDouble(),
        etaSeconds: (m['eta'] as num?)?.toDouble(),
        arrived: m['arr'] as bool? ?? false,
        climbRemainingM: (m['cr'] as num?)?.toDouble(),
        climbGainLeftM: (m['cg'] as num?)?.toDouble(),
        events: [for (final e in (m['ev'] as List? ?? const [])) e as String],
      );
}

/// The pure recording engine (spec Phase 6). Filters fixes, accumulates
/// distance, moving and active time, gain and loss (DEM with 5 m hysteresis
/// when a tile is cached, else a 5-point GPS median offset to the last DEM
/// reading; never raw GPS deltas), runs auto-pause, projects onto a followed
/// route (progress, distance remaining, remaining gain, ETA from Naismith
/// scaled by the hiker's own observed pace), and drives the off-route state
/// machine (60 m for 30 s to enter, 30 m to leave, accuracy-gated, mutable).
///
/// No I/O and no clock of its own: the caller passes timestamps. Every
/// accepted fix and every pause transition is emitted as a log line
/// ([drainLogLines]) and can be fed back with [replayLine], which restores the
/// identical state after the process was killed. Runs in the foreground task
/// isolate, never on the UI isolate.
class RecordingEngine {
  RecordingEngine({
    required this.startedAt,
    this.options = const RecordingEngineOptions(),
    List<List<double>>? route,
    List<double>? routeElev,
  }) {
    if (route != null && route.length >= 2) _setRoute(route, routeElev);
  }

  final DateTime startedAt;
  final RecordingEngineOptions options;

  final List<EnginePoint> _points = [];
  List<EnginePoint> get points => List.unmodifiable(_points);

  RecordingPhase _phase = RecordingPhase.recording;
  RecordingPhase get phase => _phase;

  int _pausedMs = 0;
  DateTime? _pauseStart;
  double? _pauseLat;
  double? _pauseLon;
  int _movedFixes = 0;

  double _distanceM = 0;
  int _movingMs = 0;
  double _currentSpeed = 0;
  DateTime? _lastMoveAt;
  int? _lastFixMs;
  double? _lastLat;
  double? _lastLon;
  double? _curLat;
  double? _curLon;
  double? _heading;
  int _fixSeq = 0;

  double? _elevRef;
  double _gainM = 0;
  double _lossM = 0;
  double? _currentElev;
  final List<double> _gpsWindow = [];
  double? _demGpsOffset;
  bool _seenDem = false;

  List<List<double>>? _route;
  List<double>? _cum;
  double _routeLen = 0;
  List<double>? _gainPrefix;
  List<double>? _lossPrefix;
  List<Climb> _climbs = const [];
  int _lastSeg = 0;
  double? _progressM;
  double? _offDistM;
  double? _bearingBack;
  bool _onRoute = true;
  bool _routeKnown = false;
  DateTime? _offSince;
  bool _muted = false;
  bool _arrived = false;

  final List<String> _events = [];
  final List<String> _logLines = [];
  bool _replaying = false;

  bool get hasRoute => _route != null;
  double get routeLengthM => _routeLen;
  bool get onRoute => _onRoute;
  bool get arrived => _arrived;
  bool get offRouteMuted => _muted;
  double? get offRouteDistanceM => _offDistM;

  void _setRoute(List<List<double>> route, List<double>? elev) {
    _route = route;
    final cum = List<double>.filled(route.length, 0);
    for (var i = 1; i < route.length; i++) {
      cum[i] = cum[i - 1] +
          haversineMeters(
              route[i - 1][0], route[i - 1][1], route[i][0], route[i][1]);
    }
    _cum = cum;
    _routeLen = cum.last;
    if (elev != null && elev.length == route.length) {
      // Cumulative hysteresis gain and loss at each vertex, so remaining gain
      // is total minus the prefix at the current position.
      final g = List<double>.filled(route.length, 0);
      final l = List<double>.filled(route.length, 0);
      var ref = elev.first;
      var gain = 0.0;
      var loss = 0.0;
      for (var i = 1; i < elev.length; i++) {
        final diff = elev[i] - ref;
        if (diff.abs() >= options.gainThresholdM) {
          if (diff > 0) {
            gain += diff;
          } else {
            loss -= diff;
          }
          ref = elev[i];
        }
        g[i] = gain;
        l[i] = loss;
      }
      _gainPrefix = g;
      _lossPrefix = l;
      _climbs = findClimbs(cum, elev);
    }
  }

  /// The climb in progress, as (distance left, gain left) to its top.
  ({double remainingM, double gainLeftM})? get currentClimb {
    final p = _progressM;
    if (p == null) return null;
    final c = climbAt(_climbs, p);
    if (c == null || c.lengthM <= 0) return null;
    final remaining = c.endM - p;
    return (
      remainingM: remaining,
      gainLeftM: c.gainM * (remaining / c.lengthM).clamp(0.0, 1.0),
    );
  }

  /// Feeds a live fix. Returns true when it was accepted. Manual pause drops
  /// every fix; auto-pause accepts only the fixes that prove the hiker moved.
  bool addFix(RecordingSample s, {double? demAltM, double? heading}) {
    if (_phase == RecordingPhase.paused) return false;
    if (s.accuracyM != null && s.accuracyM! > options.maxAccuracyM) {
      return false;
    }
    if (_lastFixMs != null && _lastLat != null) {
      final dtMs = s.t.millisecondsSinceEpoch - _lastFixMs!;
      if (dtMs <= 0) return false;
      final dist = haversineMeters(_lastLat!, _lastLon!, s.lat, s.lon);
      if (dist / (dtMs / 1000.0) > options.maxSpeedMps) return false; // jump
    }
    if (_phase == RecordingPhase.autoPaused) {
      final fromPause = (_pauseLat == null)
          ? double.infinity
          : haversineMeters(_pauseLat!, _pauseLon!, s.lat, s.lon);
      final fast =
          s.speedMps != null && s.speedMps! >= options.autoResumeSpeedMps;
      if (fast || fromPause > 8) {
        _movedFixes++;
      } else {
        _movedFixes = 0;
      }
      if (fromPause > 15 || _movedFixes >= options.autoResumeFixes) {
        _exitPause(s.t, auto: true);
      } else {
        return false;
      }
    }
    _accept(
      EnginePoint(
        seq: _points.length,
        tMs: s.t.millisecondsSinceEpoch,
        lat: s.lat,
        lon: s.lon,
        gpsAltM: s.elevM,
        demAltM: demAltM,
        accuracyM: s.accuracyM,
        speedMps: s.speedMps,
      ),
      heading: heading,
    );
    return true;
  }

  void _accept(EnginePoint p, {double? heading}) {
    final t = p.t;
    var moving = false;
    if (_lastFixMs != null && _lastLat != null) {
      final dtMs = p.tMs - _lastFixMs!;
      final dist = haversineMeters(_lastLat!, _lastLon!, p.lat, p.lon);
      _distanceM += dist;
      final implied = dtMs > 0 ? dist / (dtMs / 1000.0) : 0.0;
      _currentSpeed = p.speedMps ?? implied;
      moving = implied > options.movingThresholdMps ||
          (p.speedMps ?? 0) > options.movingThresholdMps;
      if (moving && dtMs > 0) _movingMs += dtMs;
    } else {
      _currentSpeed = p.speedMps ?? 0;
      moving = (p.speedMps ?? 0) > options.movingThresholdMps;
    }
    _lastFixMs = p.tMs;
    _lastLat = p.lat;
    _lastLon = p.lon;
    _curLat = p.lat;
    _curLon = p.lon;
    if (heading != null) _heading = heading;
    if (moving) {
      _lastMoveAt = t;
    } else {
      _lastMoveAt ??= t;
    }

    _feedElevation(p);
    _project(p);

    _points.add(p);
    _fixSeq++;
    if (!_replaying) _logLines.add(jsonEncode({'p': p.toLogList()}));
    _checkAutoPause(t);
  }

  static double _median(List<double> v) {
    final s = List.of(v)..sort();
    final n = s.length;
    return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
  }

  void _feedElevation(EnginePoint p) {
    if (p.gpsAltM != null) {
      _gpsWindow.add(p.gpsAltM!);
      if (_gpsWindow.length > 5) _gpsWindow.removeAt(0);
    }
    double? e;
    var fromDem = false;
    if (p.demAltM != null) {
      e = p.demAltM;
      fromDem = true;
      if (p.gpsAltM != null) _demGpsOffset = p.demAltM! - p.gpsAltM!;
    } else if (_gpsWindow.isNotEmpty) {
      e = _median(_gpsWindow) + (_demGpsOffset ?? 0);
    }
    if (e == null) return;
    _currentElev = e;
    if (fromDem && !_seenDem) {
      // First DEM reading after GPS-only samples: re-anchor rather than count
      // the ellipsoid-to-terrain offset as a climb or a drop.
      _seenDem = true;
      _elevRef = e;
      return;
    }
    if (_elevRef == null) {
      _elevRef = e;
      return;
    }
    final diff = e - _elevRef!;
    if (diff.abs() >= options.gainThresholdM) {
      if (diff > 0) {
        _gainM += diff;
      } else {
        _lossM -= diff;
      }
      _elevRef = e;
    }
  }

  void _project(EnginePoint p) {
    final route = _route;
    final cum = _cum;
    if (route == null || cum == null) return;
    // Search near the last match first (a trail can be thousands of vertices),
    // then the whole line if that does not put us on the route.
    final lo = (_lastSeg - 15).clamp(0, route.length - 2);
    final hi = (_lastSeg + 40).clamp(1, route.length - 1);
    var np = nearestPointOnPolyline(p.lat, p.lon, route, start: lo, end: hi);
    if (np == null || np.distanceM > options.offRouteM) {
      final full = nearestPointOnPolyline(p.lat, p.lon, route);
      if (full != null && (np == null || full.distanceM < np.distanceM)) {
        np = full;
      }
    }
    if (np == null) return;
    _lastSeg = np.segmentIndex;
    final segLen = cum[np.segmentIndex + 1] - cum[np.segmentIndex];
    _progressM = cum[np.segmentIndex] + np.t * segLen;
    _offDistM = np.distanceM;
    _bearingBack =
        np.distanceM > 5 ? bearingDegrees(p.lat, p.lon, np.lat, np.lon) : null;

    final t = p.t;
    final goodFix =
        p.accuracyM == null || p.accuracyM! <= options.offRouteMaxAccuracyM;
    if (goodFix) _routeKnown = true;
    if (_onRoute) {
      if (np.distanceM > options.offRouteM) {
        if (goodFix) {
          _offSince ??= t;
          if (t.difference(_offSince!).inSeconds >= options.offRouteDwellS) {
            _onRoute = false;
            if (!_muted && !_replaying) _events.add('offRoute');
          }
        }
      } else {
        _offSince = null;
      }
    } else if (np.distanceM <= options.onRouteM) {
      _onRoute = true;
      _offSince = null;
      _muted = false; // back on the trail re-arms the alert
    }

    if (!_arrived &&
        _onRoute &&
        _routeLen - _progressM! <= options.arriveWithinM &&
        _progressM! >= 0.9 * _routeLen) {
      _arrived = true;
      if (!_replaying) _events.add('arrived');
    }
  }

  void _checkAutoPause(DateTime now) {
    if (_replaying || !options.autoPause) return;
    if (_phase != RecordingPhase.recording) return;
    final last = _lastMoveAt;
    if (last == null) return;
    if (now.difference(last).inSeconds >= options.autoPauseAfterS) {
      _enterPause(now, auto: true);
    }
  }

  /// Time-based checks with no new fix: a stationary phone under a distance
  /// filter sends nothing, so auto-pause needs the clock.
  void tick(DateTime now) => _checkAutoPause(now);

  void pause(DateTime now) => _enterPause(now, auto: false);
  void resume(DateTime now) => _exitPause(now, auto: false);

  /// Silences the off-route alert until the hiker is back on the route.
  void muteOffRoute(DateTime now) {
    _muted = true;
    _log({'e': 'm', 't': now.millisecondsSinceEpoch});
  }

  void _enterPause(DateTime t, {required bool auto}) {
    if (_phase == RecordingPhase.paused) return;
    if (_phase == RecordingPhase.autoPaused) {
      if (auto) return;
      _phase = RecordingPhase.paused; // the interval simply continues
      if (!_replaying) _events.add('paused');
      _log({'e': 'p', 't': t.millisecondsSinceEpoch});
      return;
    }
    _phase = auto ? RecordingPhase.autoPaused : RecordingPhase.paused;
    _pauseStart = t;
    _pauseLat = _lastLat;
    _pauseLon = _lastLon;
    _movedFixes = 0;
    if (!_replaying) _events.add(auto ? 'autoPaused' : 'paused');
    _log({'e': auto ? 'ap' : 'p', 't': t.millisecondsSinceEpoch});
  }

  void _exitPause(DateTime t, {required bool auto}) {
    if (_phase == RecordingPhase.recording) return;
    final start = _pauseStart;
    if (start != null) {
      final ms = t.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      if (ms > 0) _pausedMs += ms;
    }
    _phase = RecordingPhase.recording;
    _pauseStart = null;
    if (auto) {
      // The hiker walked away from the pause spot: that distance is real, but
      // the time waiting is not moving time.
      _lastFixMs = t.millisecondsSinceEpoch;
    } else {
      // A manual pause is a gap: the next fix starts a fresh segment.
      _lastFixMs = null;
      _lastLat = null;
      _lastLon = null;
    }
    _lastMoveAt = t;
    if (!_replaying) _events.add(auto ? 'autoResumed' : 'resumed');
    _log({'e': auto ? 'ar' : 'r', 't': t.millisecondsSinceEpoch});
  }

  void _log(Map<String, Object?> line) {
    if (!_replaying) _logLines.add(jsonEncode(line));
  }

  /// Log lines produced since the previous drain, oldest first.
  List<String> drainLogLines() {
    final out = List.of(_logLines);
    _logLines.clear();
    return out;
  }

  /// Applies one durable-log line. Fixes bypass the filters (they were accepted
  /// when written) and pause transitions replay exactly, so the restored state
  /// matches the one that wrote the log.
  void replayLine(String line) {
    final m = jsonDecode(line) as Map<String, dynamic>;
    _replaying = true;
    try {
      final p = m['p'];
      if (p is List) {
        _accept(EnginePoint.fromLogList(p));
        return;
      }
      final e = m['e'] as String?;
      final t = DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt());
      switch (e) {
        case 'p':
          _enterPause(t, auto: false);
        case 'ap':
          _enterPause(t, auto: true);
        case 'r':
          _exitPause(t, auto: false);
        case 'ar':
          _exitPause(t, auto: true);
        case 'm':
          _muted = true;
      }
    } finally {
      _replaying = false;
    }
  }

  int elapsedSeconds(DateTime now) {
    final s = now.difference(startedAt).inSeconds;
    return s < 0 ? 0 : s;
  }

  int totalSeconds(DateTime now) {
    var ms = now.millisecondsSinceEpoch - startedAt.millisecondsSinceEpoch;
    ms -= _pausedMs;
    final ps = _pauseStart;
    if (ps != null) {
      ms -= now.millisecondsSinceEpoch - ps.millisecondsSinceEpoch;
    }
    return ms < 0 ? 0 : ms ~/ 1000;
  }

  RecordingStats stats(DateTime now) => RecordingStats(
        distanceM: _distanceM,
        movingSeconds: _movingMs ~/ 1000,
        totalSeconds: totalSeconds(now),
        gainM: _gainM,
        lossM: _lossM,
        currentSpeedMps: _phase == RecordingPhase.recording ? _currentSpeed : 0,
        currentElevM: _currentElev,
        pointCount: _points.length,
      );

  double? get progressM => _progressM;

  double? get remainingM {
    final p = _progressM;
    if (_route == null || p == null) return null;
    final r = _routeLen - p;
    return r < 0 ? 0 : r;
  }

  double? get remainingGainM {
    final g = _gainPrefix;
    if (g == null || _progressM == null) return null;
    final i = (_lastSeg + 1).clamp(0, g.length - 1);
    final r = g.last - g[i];
    return r < 0 ? 0 : r;
  }

  double? get _remainingLossM {
    final l = _lossPrefix;
    if (l == null || _progressM == null) return null;
    final i = (_lastSeg + 1).clamp(0, l.length - 1);
    final r = l.last - l[i];
    return r < 0 ? 0 : r;
  }

  /// Seconds of walking left to the route end: Naismith and Langmuir on the
  /// remaining distance and profile, scaled by how the hiker's own moving pace
  /// so far compares with Naismith on what they have covered (weight ramps to
  /// full after 30 minutes of moving; clamped to 0.6 to 2.5). Null without a
  /// route.
  double? etaSeconds() {
    final remaining = remainingM;
    if (remaining == null) return null;
    var eta = naismithLangmuirSeconds(
      distanceM: remaining,
      gainM: remainingGainM ?? 0,
      gentleDescentM: _remainingLossM ?? 0,
      steepDescentM: 0,
    );
    final movingS = _movingMs / 1000.0;
    if (movingS >= 300 && _distanceM >= 300) {
      final expected = naismithLangmuirSeconds(
        distanceM: _distanceM,
        gainM: _gainM,
        gentleDescentM: _lossM,
        steepDescentM: 0,
      );
      if (expected > 60) {
        final r = (movingS / expected).clamp(0.6, 2.5);
        final w = (movingS / 1800.0).clamp(0.0, 1.0);
        eta *= 1 + w * (r - 1);
      }
    }
    return eta;
  }

  /// The current report. One-shot events are handed out once.
  RecordingSnapshot snapshot(DateTime now) {
    final events = List.of(_events);
    _events.clear();
    return RecordingSnapshot(
      phase: _phase,
      stats: stats(now),
      elapsedSeconds: elapsedSeconds(now),
      fixSeq: _fixSeq,
      lat: _curLat,
      lon: _curLon,
      heading: _heading,
      onRoute: _onRoute,
      routeKnown: _routeKnown,
      offRouteDistanceM: _offDistM,
      bearingBackDeg: _bearingBack,
      offRouteMuted: _muted,
      progressM: _progressM,
      remainingM: remainingM,
      remainingGainM: remainingGainM,
      etaSeconds: etaSeconds(),
      arrived: _arrived,
      climbRemainingM: currentClimb?.remainingM,
      climbGainLeftM: currentClimb?.gainLeftM,
      events: events,
    );
  }
}
