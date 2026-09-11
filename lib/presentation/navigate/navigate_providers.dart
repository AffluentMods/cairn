// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/models/offline_region.dart';
import '../saved/library_providers.dart';
import 'route_editor_provider.dart';

/// True while Navigate is in customize (edit) mode: map taps add waypoints and
/// the edit toolbar shows (Addendum A4.3).
final editModeProvider = StateProvider<bool>((ref) => false);

/// True while the add-waypoint button is armed: the next map tap drops a pin
/// (Addendum A4.5).
final dropWaypointModeProvider = StateProvider<bool>((ref) => false);

/// All user-dropped waypoints, live.
final userWaypointsProvider = StreamProvider<List<UserWaypoint>>(
  (ref) => ref.watch(userWaypointsRepositoryProvider).watchAll(),
);

/// The route's bounding box as [minLat, minLon, maxLat, maxLon], or null when
/// there is no route.
List<double>? routeBboxOf(List<List<double>> poly) {
  if (poly.length < 2) return null;
  var minLat = poly.first[0], maxLat = poly.first[0];
  var minLon = poly.first[1], maxLon = poly.first[1];
  for (final p in poly) {
    if (p[0] < minLat) minLat = p[0];
    if (p[0] > maxLat) maxLat = p[0];
    if (p[1] < minLon) minLon = p[1];
    if (p[1] > maxLon) maxLon = p[1];
  }
  return [minLat, minLon, maxLat, maxLon];
}

/// Whether a completed offline region already contains the active route, so the
/// Download button becomes a quiet "Downloaded" label and Start turns gold
/// (Addendum A4.2).
final routeCoveredProvider = Provider<bool>((ref) {
  final poly = ref.watch(routeEditorProvider.select((s) => s.polyline));
  final bbox = routeBboxOf(poly);
  if (bbox == null) return false;
  final regions = ref.watch(offlineRegionsProvider).valueOrNull ?? const [];
  for (final r in regions) {
    if (r.status != OfflineStatus.done) continue;
    if (r.minLat <= bbox[0] &&
        r.maxLat >= bbox[2] &&
        r.minLon <= bbox[1] &&
        r.maxLon >= bbox[3]) {
      return true;
    }
  }
  return false;
});
