// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/elevation_stats.dart';
import '../../core/geo/resample.dart';
import '../repositories/elevation_repository.dart';

/// One point of the elevation profile: distance from the start and elevation.
class ProfilePoint {
  const ProfilePoint(this.distanceM, this.elevM);
  final double distanceM;
  final double elevM;
}

/// Distance, elevation, time, and the profile for a route or track.
class RouteStats {
  const RouteStats({
    required this.distanceM,
    required this.gainM,
    required this.lossM,
    required this.maxElevM,
    required this.minElevM,
    required this.estimatedTime,
    required this.profile,
  });

  final double distanceM;
  final double gainM;
  final double lossM;
  final double maxElevM;
  final double minElevM;
  final Duration estimatedTime;
  final List<ProfilePoint> profile;

  static const empty = RouteStats(
    distanceM: 0,
    gainM: 0,
    lossM: 0,
    maxElevM: 0,
    minElevM: 0,
    estimatedTime: Duration.zero,
    profile: [],
  );
}

/// Grade steeper than this counts as steep descent for the time estimate.
const _steepGrade = 0.20;

/// Computes route statistics from a `[lat, lon]` polyline: resamples every
/// [sampleSpacingM] meters, looks up DEM elevation, then applies hysteresis
/// gain/loss and a Naismith/Langmuir time estimate (spec Section 8, Phase 3).
Future<RouteStats> computeRouteStats(
  List<List<double>> polyline,
  ElevationRepository elevation, {
  double sampleSpacingM = 20,
}) async {
  if (polyline.length < 2) return RouteStats.empty;

  final samples = resampleByDistance(polyline, sampleSpacingM);
  final elevs = await elevation.elevationsAlong(
    samples.map((s) => [s.lat, s.lon]).toList(),
  );
  if (elevs.length != samples.length) return RouteStats.empty;

  final stats = gainLoss(elevs);

  var gentleDescent = 0.0;
  var steepDescent = 0.0;
  for (var i = 1; i < samples.length; i++) {
    final dh = elevs[i] - elevs[i - 1];
    final dd = samples[i].distanceM - samples[i - 1].distanceM;
    if (dh < 0 && dd > 0) {
      final grade = -dh / dd;
      if (grade > _steepGrade) {
        steepDescent += -dh;
      } else {
        gentleDescent += -dh;
      }
    }
  }

  final totalDistance = samples.last.distanceM;
  final seconds = naismithLangmuirSeconds(
    distanceM: totalDistance,
    gainM: stats.gain,
    gentleDescentM: gentleDescent,
    steepDescentM: steepDescent,
  );

  return RouteStats(
    distanceM: totalDistance,
    gainM: stats.gain,
    lossM: stats.loss,
    maxElevM: stats.maxElev,
    minElevM: stats.minElev,
    estimatedTime: Duration(seconds: seconds.round()),
    profile: [
      for (var i = 0; i < samples.length; i++)
        ProfilePoint(samples[i].distanceM, elevs[i]),
    ],
  );
}
