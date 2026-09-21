// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

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

/// The most trail line features we ever hand MapLibre in one update (Fix Pass 1
/// X1.3.4). Past this the platform-channel transfer and render cost is not worth
/// the detail at any readable zoom.
const int maxTrailFeatures = 2000;

/// The simplification bucket for a zoom: the tolerance in meters and whether to
/// drop unnamed ways. Buckets keep [trailsSignature] and [trailsToGeoJson] in
/// step, so the signature fully predicts the built geometry.
({double tolerance, bool namedOnly}) _trailBucket(double zoom) =>
    switch (zoom) {
      < 11 => (tolerance: 60.0, namedOnly: true),
      < 13 => (tolerance: 25.0, namedOnly: false),
      < 15 => (tolerance: 8.0, namedOnly: false),
      _ => (tolerance: 0.0, namedOnly: false),
    };

/// Trails as a GeoJSON FeatureCollection of LineStrings. GeoJSON is [lon, lat];
/// our geometry is stored [lat, lon], so coordinates are swapped here. Below
/// [fullGeometryZoom] the lines are simplified to stay under the feature budget;
/// below z11 only named ways render, and the collection is capped at
/// [maxTrailFeatures] (Fix Pass 1 X1.3.4).
Map<String, dynamic> trailsToGeoJson(
  List<Trail> trails, {
  double zoom = 14,
  double fullGeometryZoom = 15,
}) {
  final bucket = _trailBucket(zoom);
  final features = <Map<String, dynamic>>[];
  for (final t in trails) {
    if (bucket.namedOnly && (t.name == null || t.name!.isEmpty)) continue;
    final geom = zoom >= fullGeometryZoom || bucket.tolerance == 0
        ? t.geometry
        : simplifyDouglasPeucker(t.geometry, bucket.tolerance);
    if (geom.length < 2) continue;
    features.add({
      'type': 'Feature',
      'properties': {
        'id': t.id,
        // The style draws forest roads (highway=track) dashed and thin and
        // keeps them out of the trail layer and its labels (Addendum A6 F2);
        // without this property every road rendered as a trail.
        'highway': t.highway,
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
    if (features.length >= maxTrailFeatures) break;
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// A cheap FNV-1a signature of the trail set as it will render at [zoom]: the
/// simplification bucket plus every trail id. Geometry is immutable per id in
/// our cache, so the bucket and the id set fully determine [trailsToGeoJson]'s
/// output. If the signature is unchanged the caller skips rebuilding and
/// re-sending the source (Fix Pass 1 X1.3.4). This is a light integer fold, so
/// it stays on the UI isolate.
int trailsSignature(List<Trail> trails, double zoom) {
  final bucket = switch (zoom) {
    < 11 => 0,
    < 13 => 1,
    < 15 => 2,
    _ => 3,
  };
  var hash = 0x811c9dc5;
  hash = (hash ^ bucket) * 0x01000193 & 0xFFFFFFFF;
  for (final t in trails) {
    final id = t.id;
    hash = (hash ^ (id & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
    hash = (hash ^ ((id >> 16) & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
  }
  return hash;
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

/// FNV-1a signature of a POI set by id, so an unchanged set is not rebuilt and
/// re-sent (Fix Pass 1 X1.3.4).
int poisSignature(List<PoiPoint> pois) {
  var hash = 0x811c9dc5;
  for (final p in pois) {
    final id = p.id.hashCode;
    hash = (hash ^ (id & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
    hash = (hash ^ ((id >> 16) & 0xFFFF)) * 0x01000193 & 0xFFFFFFFF;
  }
  return hash;
}

/// Whether a cached POI earns a marker (spec Phase 2: springs, lakes, peaks,
/// campsites, trailheads as icons). Streams and rivers stay in the cache for
/// the water-along-route helper but never draw: the base map already draws
/// them as lines, and a drop on every crossing buried the map. A lake shows
/// only when it has a name, for the same reason.
bool poiDrawsOnMap(PoiPoint p) => switch (p.kind) {
      'stream' || 'river' => false,
      'water' => p.name != null && p.name!.isNotEmpty,
      _ => true,
    };

Map<String, dynamic> poisToGeoJson(List<PoiPoint> pois) {
  return {
    'type': 'FeatureCollection',
    'features': [
      for (final p in pois)
        if (poiDrawsOnMap(p))
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
      // Flame icons scale with acres on a log scale (spec Phase 7): 0 for a
      // spot fire up to 5 for 100,000 acres; the style interpolates the size.
      if (f.acres != null)
        'sizeIdx': math.log(f.acres! + 1) / math.ln10 > 5
            ? 5.0
            : math.log(f.acres! + 1) / math.ln10,
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
