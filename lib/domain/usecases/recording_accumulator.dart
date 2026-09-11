// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';

/// One GPS fix handed to the accumulator.
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
}

/// Accumulates filtered GPS fixes into live stats (spec Phase 6). Drops points
/// with accuracy worse than [maxAccuracyM] and points implying a speed over
/// [maxSpeedMps] (GPS jumps). Moving time accrues only while moving faster than
/// [movingThresholdMps]. Gain uses elevation hysteresis so DEM noise does not
/// add phantom feet.
class RecordingAccumulator {
  RecordingAccumulator({
    this.maxAccuracyM = 30,
    this.maxSpeedMps = 12,
    this.movingThresholdMps = 0.5,
    this.gainThresholdM = 5,
  });

  final double maxAccuracyM;
  final double maxSpeedMps;
  final double movingThresholdMps;
  final double gainThresholdM;

  final _polyline = <List<double>>[];

  DateTime? _startTime;
  DateTime? _lastTime;
  double? _lastLat;
  double? _lastLon;
  double? _elevRef; // hysteresis reference

  double _distanceM = 0;
  int _movingSeconds = 0;
  double _gainM = 0;
  double _lossM = 0;
  double _currentSpeed = 0;
  double? _currentElev;
  int _pointCount = 0;

  List<List<double>> get polyline => List.unmodifiable(_polyline);

  /// Feeds a sample. Returns true if it was accepted (passed the filters).
  bool add(RecordingSample s) {
    if (s.accuracyM != null && s.accuracyM! > maxAccuracyM) return false;

    _startTime ??= s.t;
    if (_lastLat != null && _lastTime != null) {
      final dist = haversineMeters(_lastLat!, _lastLon!, s.lat, s.lon);
      final dt = s.t.difference(_lastTime!).inMilliseconds / 1000.0;
      if (dt <= 0) return false;
      final impliedSpeed = dist / dt;
      if (impliedSpeed > maxSpeedMps) return false; // GPS jump

      _distanceM += dist;
      _currentSpeed = s.speedMps ?? impliedSpeed;
      if (_currentSpeed > movingThresholdMps) {
        _movingSeconds += dt.round();
      }
    }

    // Elevation hysteresis.
    final elev = s.elevM;
    if (elev != null) {
      _currentElev = elev;
      if (_elevRef == null) {
        _elevRef = elev;
      } else {
        final diff = elev - _elevRef!;
        if (diff.abs() >= gainThresholdM) {
          if (diff > 0) {
            _gainM += diff;
          } else {
            _lossM += -diff;
          }
          _elevRef = elev;
        }
      }
    }

    _polyline.add([s.lat, s.lon]);
    _lastLat = s.lat;
    _lastLon = s.lon;
    _lastTime = s.t;
    _pointCount++;
    return true;
  }

  RecordingStats statsAt(DateTime now) {
    final total =
        _startTime == null ? 0 : now.difference(_startTime!).inSeconds;
    return RecordingStats(
      distanceM: _distanceM,
      movingSeconds: _movingSeconds,
      totalSeconds: total < 0 ? 0 : total,
      gainM: _gainM,
      lossM: _lossM,
      currentSpeedMps: _currentSpeed,
      currentElevM: _currentElev,
      pointCount: _pointCount,
    );
  }
}
