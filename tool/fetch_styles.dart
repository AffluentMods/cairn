// SPDX-License-Identifier: GPL-3.0-or-later
//
// Builds assets/map_styles/outdoors.json by snapshotting the OpenFreeMap
// "liberty" vector style and appending Cairn's terrain source, a hillshade
// layer, and the six cairn-* overlay sources and layers (spec Section 8, Phase
// 1). Snapshotting (not hotlinking) means the offline style just works.
//
// Run: dart run tool/fetch_styles.dart
import 'dart:convert';
import 'dart:io';

const _libertyUrl = 'https://tiles.openfreemap.org/styles/liberty';
const _outPath = 'assets/map_styles/outdoors.json';

Map<String, dynamic> _emptyGeojson() => {
      'type': 'geojson',
      'data': {'type': 'FeatureCollection', 'features': <dynamic>[]},
    };

/// The overlay layers shared by every Cairn style, drawn on top of the base.
List<Map<String, dynamic>> _overlayLayers() => [
      {
        'id': 'land-line',
        'type': 'line',
        'source': 'cairn-land',
        'paint': {
          'line-color': ['get', 'stroke'],
          'line-width': 1.5,
          'line-dasharray': [3, 2],
        },
      },
      {
        'id': 'fires-fill',
        'type': 'fill',
        'source': 'cairn-fires',
        'filter': ['==', ['geometry-type'], 'Polygon'],
        'paint': {
          'fill-color': ['case', ['==', ['get', 'prescribed'], true], '#F5A524', '#E5484D'],
          'fill-opacity': 0.28,
        },
      },
      {
        'id': 'fires-line',
        'type': 'line',
        'source': 'cairn-fires',
        'filter': ['==', ['geometry-type'], 'Polygon'],
        'paint': {
          'line-color': ['case', ['==', ['get', 'prescribed'], true], '#F5A524', '#E5484D'],
          'line-width': 2,
        },
      },
      {
        'id': 'trails-casing',
        'type': 'line',
        'source': 'cairn-trails',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {'line-color': '#F6F3EC', 'line-width': 4, 'line-opacity': 0.7},
      },
      {
        'id': 'trails',
        'type': 'line',
        'source': 'cairn-trails',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': ['case', ['==', ['get', 'informal'], true], '#9C8A6E', '#6B4F2A'],
          'line-width': ['interpolate', ['linear'], ['zoom'], 10, 1, 14, 2.5, 17, 4],
          'line-dasharray': ['case', ['==', ['get', 'informal'], true], ['literal', [2, 2]], ['literal', [1, 0]]],
        },
      },
      {
        'id': 'route-casing',
        'type': 'line',
        'source': 'cairn-route',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {'line-color': '#0E1412', 'line-width': 7, 'line-opacity': 0.6},
      },
      {
        'id': 'route',
        'type': 'line',
        'source': 'cairn-route',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#D9A441',
          'line-width': 4,
          'line-dasharray': ['case', ['==', ['get', 'offTrail'], true], ['literal', [2, 2]], ['literal', [1, 0]]],
        },
      },
      {
        'id': 'track',
        'type': 'line',
        'source': 'cairn-track',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {'line-color': '#3FB8AF', 'line-width': 3.5},
      },
      {
        'id': 'fires-point',
        'type': 'symbol',
        'source': 'cairn-fires',
        'filter': ['==', ['geometry-type'], 'Point'],
        'layout': {'icon-image': 'fire', 'icon-size': 0.9, 'icon-allow-overlap': true},
      },
      {
        'id': 'pois',
        'type': 'symbol',
        'source': 'cairn-pois',
        'layout': {
          'icon-image': ['get', 'icon'],
          'icon-size': 0.9,
          'icon-allow-overlap': false,
          'text-field': ['get', 'name'],
          'text-size': 11,
          'text-offset': [0, 1.2],
          'text-optional': true,
        },
        'paint': {'text-halo-color': '#F6F3EC', 'text-halo-width': 1.2},
      },
    ];

Future<void> main() async {
  stdout.writeln('Fetching liberty style from $_libertyUrl');
  final client = HttpClient();
  Map<String, dynamic> style;
  try {
    final req = await client.getUrl(Uri.parse(_libertyUrl));
    final res = await req.close();
    if (res.statusCode != 200) {
      throw HttpException('status ${res.statusCode}');
    }
    final body = await res.transform(utf8.decoder).join();
    style = jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close();
  }

  final sources = (style['sources'] as Map<String, dynamic>);
  sources['terrain-dem'] = {
    'type': 'raster-dem',
    'tiles': ['https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png'],
    'tileSize': 256,
    'encoding': 'terrarium',
    'minzoom': 0,
    'maxzoom': 15,
    'attribution': 'Terrain: Mapzen / AWS Terrain Tiles',
  };
  for (final s in ['cairn-land', 'cairn-fires', 'cairn-trails', 'cairn-route', 'cairn-track', 'cairn-pois']) {
    sources[s] = _emptyGeojson();
  }

  final layers = (style['layers'] as List).cast<Map<String, dynamic>>();

  // Insert hillshade after the last water fill layer so relief sits under roads
  // and labels. Fall back to just after the background layer.
  var insertAt = 1;
  for (var i = 0; i < layers.length; i++) {
    final id = (layers[i]['id'] as String?)?.toLowerCase() ?? '';
    if (id.contains('water') || id.contains('landcover') || id.contains('landuse')) {
      insertAt = i + 1;
    }
  }
  layers.insert(insertAt, {
    'id': 'hillshade',
    'type': 'hillshade',
    'source': 'terrain-dem',
    'paint': {'hillshade-exaggeration': 0.35, 'hillshade-shadow-color': '#2b2b2b'},
  });

  layers.addAll(_overlayLayers());
  style['layers'] = layers;
  style['name'] = 'Cairn Outdoors';

  final out = File(_outPath);
  await out.writeAsString(const JsonEncoder.withIndent('  ').convert(style));
  stdout.writeln('Wrote $_outPath (${layers.length} layers, ${sources.length} sources)');
}
