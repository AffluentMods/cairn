// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The live map controller, set in onMapCreated. Null until the map exists.
final mapControllerProvider = StateProvider<MapLibreMapController?>((ref) => null);

/// The visible map area and zoom, updated when the camera settles. Data layers
/// (Phase 2 onward) watch this to decide which cells to load.
class MapViewport {
  const MapViewport({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.zoom,
  });

  final double south;
  final double west;
  final double north;
  final double east;
  final double zoom;

  /// (south, west, north, east), the order the data sources expect.
  List<double> get bbox => [south, west, north, east];
}

class ViewportNotifier extends Notifier<MapViewport?> {
  @override
  MapViewport? build() => null;

  Future<void> updateFrom(MapLibreMapController controller) async {
    final bounds = await controller.getVisibleRegion();
    final zoom = controller.cameraPosition?.zoom ?? 0;
    state = MapViewport(
      south: bounds.southwest.latitude,
      west: bounds.southwest.longitude,
      north: bounds.northeast.latitude,
      east: bounds.northeast.longitude,
      zoom: zoom,
    );
  }
}

final viewportProvider = NotifierProvider<ViewportNotifier, MapViewport?>(
  ViewportNotifier.new,
);

const _kCamLat = 'map.cam.lat';
const _kCamLon = 'map.cam.lon';
const _kCamZoom = 'map.cam.zoom';

/// Default camera: Goat Rocks / Mount Rainier country (spec Section 8).
const _defaultCamera = CameraPosition(target: LatLng(46.75, -121.5), zoom: 9);

/// The camera to open the map at, restored from the last session (spec Phase 1
/// acceptance: camera persists across restarts).
CameraPosition initialCamera(SharedPreferences prefs) {
  final lat = prefs.getDouble(_kCamLat);
  final lon = prefs.getDouble(_kCamLon);
  final zoom = prefs.getDouble(_kCamZoom);
  if (lat == null || lon == null || zoom == null) return _defaultCamera;
  return CameraPosition(target: LatLng(lat, lon), zoom: zoom);
}

Future<void> persistCamera(
  SharedPreferences prefs,
  MapLibreMapController controller,
) async {
  final cam = controller.cameraPosition;
  if (cam == null) return;
  await prefs.setDouble(_kCamLat, cam.target.latitude);
  await prefs.setDouble(_kCamLon, cam.target.longitude);
  await prefs.setDouble(_kCamZoom, cam.zoom);
}

/// True once the user has granted location and the puck should render.
final locationEnabledProvider = StateProvider<bool>((ref) => false);
