// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/polyline_simplify.dart';
import '../../core/worker/geo_worker.dart';
import '../../domain/models/fire_incident.dart';
import '../../domain/models/land_unit.dart';
import '../../domain/models/poi.dart';
import '../../domain/models/trail.dart';

/// An empty GeoJSON FeatureCollection, for clearing a source.
Map<String, dynamic> emptyFeatureCollection() => {
      'type': 'FeatureCollection',
      'features': <dynamic>[],
    };

/// Trails as a GeoJSON FeatureCollection of LineStrings. GeoJSON is [lon, lat];
/// our geometry is stored [lat, lon], so coordinates are swapped here. Below
/// [fullGeometryZoom] the lines are simplified to stay under the feature budget.
Map<String, dynamic> trailsToGeoJson(
  List<Trail> trails, {
  double zoom = 14,
  double fullGeometryZoom = 15,
}) {
  final simplifyTolerance = switch (zoom) {
    < 11 => 60.0,
    < 13 => 25.0,
    < 15 => 8.0,
    _ => 0.0,
  };
  final features = <Map<String, dynamic>>[];
  for (final t in trails) {
    final geom = zoom >= fullGeometryZoom || simplifyTolerance == 0
        ? t.geometry
        : simplifyDouglasPeucker(t.geometry, simplifyTolerance);
    if (geom.length < 2) continue;
    features.add({
      'type': 'Feature',
      'properties': {
        'id': t.id,
        'informal': t.informal,
        'name': t.name ?? '',
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          for (final p in geom) [p[1], p[0]],
        ],
      },
    });
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// [trailsToGeoJson] on a worker isolate (Fix Pass 1 X1.3.1). Douglas-Peucker
/// simplification over every trail is the cost, so it never runs on the UI
/// isolate.
Future<Map<String, dynamic>> trailsToGeoJsonAsync(
  List<Trail> trails, {
  double zoom = 14,
  double fullGeometryZoom = 15,
}) =>
    GeoWorker.run(
      'trails-geojson',
      () => trailsToGeoJson(
        trails,
        zoom: zoom,
        fullGeometryZoom: fullGeometryZoom,
      ),
    );

/// The sprite image name for a POI kind (registered at runtime, see poi_icons).
String iconForKind(String kind) => switch (kind) {
      'spring' || 'water' || 'drinking_water' || 'stream' || 'river' => 'water',
      'peak' => 'peak',
      'saddle' => 'saddle',
      'camp_site' => 'camp',
      'hut' || 'shelter' => 'hut',
      'viewpoint' => 'viewpoint',
      'toilets' => 'toilets',
      'parking' => 'parking',
      'trailhead' => 'trailhead',
      _ => 'water',
    };

Map<String, dynamic> poisToGeoJson(List<PoiPoint> pois) {
  return {
    'type': 'FeatureCollection',
    'features': [
      for (final p in pois)
        {
          'type': 'Feature',
          'properties': {
            'id': p.id,
            'kind': p.kind,
            'icon': iconForKind(p.kind),
            'name': p.name ?? '',
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [p.lon, p.lat],
          },
        },
    ],
  };
}

/// Fires as GeoJSON: a Polygon feature per perimeter ring, and a Point feature
/// per incident with no perimeter. Properties carry enough to render the card.
Map<String, dynamic> firesToGeoJson(List<FireIncident> fires) {
  final features = <Map<String, dynamic>>[];
  for (final f in fires) {
    final props = {
      'id': f.id,
      'name': f.name,
      'prescribed': f.prescribed,
      if (f.acres != null) 'acres': f.acres,
      if (f.percentContained != null) 'contained': f.percentContained,
    };
    if (f.isPerimeter) {
      for (final ring in f.polygons) {
        features.add({
          'type': 'Feature',
          'properties': props,
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                for (final p in ring) [p[1], p[0]],
              ],
            ],
          },
        });
      }
    } else if (f.lat != null && f.lon != null) {
      features.add({
        'type': 'Feature',
        'properties': props,
        'geometry': {
          'type': 'Point',
          'coordinates': [f.lon, f.lat],
        },
      });
    }
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// Land units as GeoJSON Polygons, colored by kind via stroke/fill properties.
Map<String, dynamic> landToGeoJson(List<LandUnit> units) {
  final features = <Map<String, dynamic>>[];
  for (final u in units) {
    for (final ring in u.polygons) {
      features.add({
        'type': 'Feature',
        'properties': {
          'name': u.name,
          'stroke': u.strokeHex,
          'fill': u.strokeHex,
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              for (final p in ring) [p[1], p[0]],
            ],
          ],
        },
      });
    }
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// A single LineString FeatureCollection ([lat,lon] input) for the route or
/// track sources. [offTrail] marks a leg that could not be snapped to a trail.
Map<String, dynamic> lineToGeoJson(
  List<List<double>> latLon, {
  bool offTrail = false,
}) {
  return {
    'type': 'FeatureCollection',
    'features': [
      if (latLon.length >= 2)
        {
          'type': 'Feature',
          'properties': {'offTrail': offTrail},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final p in latLon) [p[1], p[0]],
            ],
          },
        },
    ],
  };
}
