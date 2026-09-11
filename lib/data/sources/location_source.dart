// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/geo/haversine.dart';

/// Where recording gets its position fixes (Fix Pass 1 X2.8). The device GPS in
/// production; a simulated walk along a route in debug or profile, so
/// navigation and follow mode can be exercised without moving.
abstract class LocationSource {
  Stream<Position> stream();
}

/// The real device GPS.
class DeviceLocationSource implements LocationSource {
  const DeviceLocationSource();

  @override
  Stream<Position> stream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );
}

/// A synthetic walk along a route, for development only.
class SimulatedLocationSource implements LocationSource {
  const SimulatedLocationSource(
    this.route, {
    this.speedMps = 1.4,
    this.interval = const Duration(seconds: 1),
  });

  final List<List<double>> route; // [[lat, lon], ...]
  final double speedMps;
  final Duration interval;

  @override
  Stream<Position> stream() =>
      simulateAlong(route, speedMps: speedMps, interval: interval);
}

/// Emits synthetic fixes walking [route] ([lat, lon] pairs) at [speedMps],
/// one every [interval], with a heading along the current segment. Pure except
/// for the timer, so its geometry can be unit tested by draining a few fixes.
Stream<Position> simulateAlong(
  List<List<double>> route, {
  double speedMps = 1.4,
  Duration interval = const Duration(seconds: 1),
}) async* {
  if (route.length < 2) return;
  final step = speedMps * (interval.inMilliseconds / 1000.0); // meters per tick
  var seg = 0;
  var into = 0.0; // meters into the current segment
  while (seg < route.length - 1) {
    final a = route[seg];
    final b = route[seg + 1];
    final segLen = haversineMeters(a[0], a[1], b[0], b[1]);
    if (segLen < 0.01) {
      seg++;
      into = 0;
      continue;
    }
    final t = (into / segLen).clamp(0.0, 1.0);
    yield _fix(
      lat: a[0] + (b[0] - a[0]) * t,
      lon: a[1] + (b[1] - a[1]) * t,
      heading: bearingDegrees(a[0], a[1], b[0], b[1]),
      speedMps: speedMps,
    );
    await Future<void>.delayed(interval);
    into += step;
    if (into >= segLen) {
      into -= segLen; // carry the remainder into the next segment
      seg++;
    }
  }
}

Position _fix({
  required double lat,
  required double lon,
  required double heading,
  required double speedMps,
}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 5,
      heading: heading,
      headingAccuracy: 5,
      speed: speedMps,
      speedAccuracy: 1,
      isMocked: true,
    );
