// SPDX-License-Identifier: GPL-3.0-or-later
//
// Rewrites the Cairn overlay layers in every bundled style so no line layer
// uses a data-driven `line-dasharray`. MapLibre Native rejects that property
// as a data expression ("[ParseStyle]: data expressions not supported") and
// silently drops the whole layer, which made OSM trails and the active route
// invisible on the map. The informal-trail and off-trail variants become their
// own layers with a constant dash and a property filter.
//
// Idempotent. Run after regenerating a style: dart run tool/patch_cairn_layers.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final dir = Directory('assets/map_styles');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final style = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final layers = (style['layers'] as List).cast<Map<String, dynamic>>();
    final a = splitDashLayer(layers, 'trails', 'trails-informal', 'informal');
    final b = splitDashLayer(layers, 'route', 'route-offtrail', 'offTrail');
    final c = ensureLayerAfter(layers, 'route-offtrail', routeArrowsLayer());
    final d = sizeFirePoints(layers);
    final f = boldTrails(layers);
    final g = upsertLayerAfter(layers, 'trails-informal', trailsLabelLayer());
    // After every Cairn symbol layer exists, so the new label gets a font too.
    final e = fixLabelFonts(style, layers);
    final vector =
        (style['sources'] as Map<String, dynamic>).containsKey('openmaptiles');
    final h = vector && outdoorBaseMap(layers);
    style['layers'] = layers;
    file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(style)}\n');
    stdout.writeln('${file.path}: trails ${a ? "split" : "ok"}, '
        'route ${b ? "split" : "ok"}, arrows ${c ? "added" : "ok"}, '
        'fire size ${d ? "set" : "ok"}, fonts ${e ? "fixed" : "ok"}, '
        'trail width ${f ? "set" : "ok"}, labels ${g ? "added" : "ok"}, '
        'base map ${!vector ? "raster" : h ? "patched" : "ok"}');
  }
}

/// Trail line widths: still thin brown lines at z11 (Addendum A6 F2, "not a
/// white web"), but a little heavier from z9 up so a trail reads at the zoom a
/// hiker scans an area at, and a touch wider close in. Returns true when
/// changed.
bool boldTrails(List<Map<String, dynamic>> layers) {
  const width = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9,
    0.9,
    11,
    1.4,
    13,
    2.2,
    15,
    3.2,
    17,
    4.5,
  ];
  var changed = false;
  for (final id in ['trails', 'trails-informal']) {
    final i = layers.indexWhere((l) => l['id'] == id);
    if (i < 0) continue;
    final paint = (layers[i]['paint'] as Map?)?.cast<String, dynamic>() ?? {};
    if (jsonEncode(paint['line-width']) == jsonEncode(width)) continue;
    paint['line-width'] = width;
    layers[i]['paint'] = paint;
    changed = true;
  }
  return changed;
}

/// Trail names along the line from z13, in the trail's own brown, so a hiker
/// can tell Snowgrass from the PCT without tapping (forest roads stay
/// unlabeled here; the base map names roads).
Map<String, dynamic> trailsLabelLayer() => {
      'id': 'trails-label',
      'type': 'symbol',
      'source': 'cairn-trails',
      'minzoom': 13,
      'filter': [
        'all',
        [
          '!=',
          ['get', 'name'],
          ''
        ],
        [
          '!=',
          ['get', 'highway'],
          'track'
        ],
      ],
      'layout': {
        'symbol-placement': 'line',
        'symbol-spacing': 250,
        'text-field': ['get', 'name'],
        'text-font': ['Noto Sans Italic'],
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          13,
          11,
          16,
          13
        ],
        // MapLibre's default bend limit. A tighter 30 degrees found no
        // straight enough run on switchbacking trails at z13 and placed none.
        'text-max-angle': 45,
        'text-padding': 4,
        'text-letter-spacing': 0.02,
        'text-rotation-alignment': 'map',
      },
      'paint': {
        'text-color': '#5A4022',
        'text-halo-color': '#F6F3EC',
        'text-halo-width': 1.6,
        'text-halo-blur': 0.5,
      },
    };

/// Outdoor cartography on the OpenMapTiles styles (outdoors, terrain, road):
/// national parks and wilderness shaded and labeled with a green dashed edge
/// that cannot be mistaken for a trail (the old pale dotted edge read as one),
/// national forests outlined only, scree and bare rock grey, glacier edges
/// blue, the base map's own path names hidden (Cairn labels its trails), and
/// Cairn's POI peaks dropped because the base map labels every summit with
/// its elevation (base_map_labels.dart). Returns true when anything changed.
bool outdoorBaseMap(List<Map<String, dynamic>> layers) {
  var changed = false;
  bool set(String id, String group, String key, Object value) {
    final i = layers.indexWhere((l) => l['id'] == id);
    if (i < 0) return false;
    final map = (layers[i][group] as Map?)?.cast<String, dynamic>() ?? {};
    if (jsonEncode(map[key]) == jsonEncode(value)) return false;
    map[key] = value;
    layers[i][group] = map;
    return true;
  }

  bool setRoot(String id, String key, Object value) {
    final i = layers.indexWhere((l) => l['id'] == id);
    if (i < 0) return false;
    if (jsonEncode(layers[i][key]) == jsonEncode(value)) return false;
    layers[i][key] = value;
    return true;
  }

  const protectedClasses = [
    'national_park',
    'nature_reserve',
    'wilderness_preserve',
  ];

  // Parks and wilderness: a light green wash; national forests (the whole
  // Cascades) get no fill, only the edge.
  changed |= setRoot('park', 'filter', [
    'match',
    ['get', 'class'],
    protectedClasses,
    true,
    false,
  ]);
  changed |= set('park', 'paint', 'fill-color', '#CDE3B4');
  changed |= set('park', 'paint', 'fill-opacity', [
    'interpolate',
    ['linear'],
    ['zoom'],
    5,
    0.45,
    10,
    0.3,
    14,
    0.2,
  ]);
  final park = layers.indexWhere((l) => l['id'] == 'park');
  if (park >= 0) {
    final paint = (layers[park]['paint'] as Map).cast<String, dynamic>();
    if (paint.remove('fill-outline-color') != null) changed = true;
  }
  changed |= set('park_outline', 'paint', 'line-color', '#6E9E5B');
  changed |= set('park_outline', 'paint', 'line-opacity', 0.7);
  changed |= set('park_outline', 'paint', 'line-dasharray', [3, 2]);
  changed |= set('park_outline', 'paint', 'line-width', [
    'interpolate',
    ['linear'],
    ['zoom'],
    8,
    0.8,
    14,
    1.6,
  ]);

  changed |= ensureLayerAfter(layers, 'landcover_ice', {
    'id': 'landcover_rock',
    'type': 'fill',
    'source': 'openmaptiles',
    'source-layer': 'landcover',
    'minzoom': 8,
    'filter': [
      '==',
      ['get', 'class'],
      'rock'
    ],
    'paint': {
      'fill-antialias': false,
      'fill-color': '#D8D2C6',
      'fill-opacity': [
        'interpolate',
        ['linear'],
        ['zoom'],
        8,
        0.35,
        13,
        0.6
      ],
    },
  });
  changed |= ensureLayerAfter(layers, 'landcover_rock', {
    'id': 'landcover_ice_outline',
    'type': 'line',
    'source': 'openmaptiles',
    'source-layer': 'landcover',
    'minzoom': 10,
    'filter': [
      '==',
      ['get', 'class'],
      'ice'
    ],
    'paint': {
      'line-color': '#9FC3D8',
      'line-opacity': 0.8,
      'line-width': [
        'interpolate',
        ['linear'],
        ['zoom'],
        10,
        0.5,
        15,
        1.2
      ],
    },
  });

  final parkLabel = layers.indexWhere((l) => l['id'] == 'park-label');
  if (parkLabel < 0) {
    final at = layers.indexWhere((l) => l['id'] == 'label_other');
    layers.insert(at < 0 ? layers.length : at, parkLabelLayer());
    changed = true;
  } else if (jsonEncode(layers[parkLabel]) != jsonEncode(parkLabelLayer())) {
    layers[parkLabel] = parkLabelLayer();
    changed = true;
  }

  changed |= set('highway-name-path', 'layout', 'visibility', 'none');

  changed |= setRoot('pois', 'filter', [
    '!=',
    ['get', 'kind'],
    'peak'
  ]);
  return changed;
}

/// National park, wilderness, and national forest names at their label
/// points, in park green (forests a shade lighter), from z8.
Map<String, dynamic> parkLabelLayer() => {
      'id': 'park-label',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'park',
      'minzoom': 8,
      'filter': [
        'all',
        [
          '==',
          ['geometry-type'],
          'Point'
        ],
        ['has', 'name'],
      ],
      'layout': {
        'text-field': [
          'coalesce',
          ['get', 'name_en'],
          ['get', 'name']
        ],
        'text-font': ['Noto Sans Italic'],
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          8,
          10,
          12,
          13
        ],
        'text-max-width': 7,
        'text-letter-spacing': 0.04,
        'text-padding': 6,
        'symbol-sort-key': ['get', 'rank'],
      },
      'paint': {
        'text-color': [
          'match',
          ['get', 'class'],
          'forest_reserve',
          '#5F7F52',
          '#3E6B35'
        ],
        'text-halo-color': 'rgba(255,255,255,0.8)',
        'text-halo-width': 1.3,
      },
    };

/// The glyph server every style can use for labels (the vector styles
/// already point here). The raster styles had none, and no Cairn symbol layer
/// named a `text-font`, so MapLibre asked for its default "Open Sans
/// Regular,Arial Unicode MS Regular" stack, got a 404, and never rendered the
/// POI layer at all (icons included). Returns true when changed.
const glyphsUrl = 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf';
const labelFont = ['Noto Sans Regular'];

/// Font stacks the glyph server above serves; a Cairn symbol layer naming one
/// of these keeps it (trail names are italic, like a paper map).
const knownFonts = [
  ['Noto Sans Regular'],
  ['Noto Sans Italic'],
  ['Noto Sans Bold'],
];

bool fixLabelFonts(
  Map<String, dynamic> style,
  List<Map<String, dynamic>> layers,
) {
  var changed = false;
  if (style['glyphs'] != glyphsUrl) {
    style['glyphs'] = glyphsUrl;
    changed = true;
  }
  for (final layer in layers) {
    if (layer['type'] != 'symbol') continue;
    final source = layer['source'];
    if (source is! String || !source.startsWith('cairn-')) continue;
    final layout = (layer['layout'] as Map?)?.cast<String, dynamic>() ?? {};
    if (!layout.containsKey('text-field')) continue;
    final font = jsonEncode(layout['text-font']);
    if (knownFonts.any((f) => jsonEncode(f) == font)) continue;
    layout['text-font'] = labelFont;
    layer['layout'] = layout;
    changed = true;
  }
  return changed;
}

/// Flame icons sized by acres on a log scale (spec Phase 7). `sizeIdx` is
/// log10(acres + 1) capped at 5, written by `firesToGeoJson`; a fire with no
/// acreage draws at the middle size. `icon-size` accepts data expressions on
/// MapLibre Native, unlike `line-dasharray`. Returns true when changed.
bool sizeFirePoints(List<Map<String, dynamic>> layers) {
  final i = layers.indexWhere((l) => l['id'] == 'fires-point');
  if (i < 0) return false;
  final layout = (layers[i]['layout'] as Map?)?.cast<String, dynamic>() ?? {};
  const want = [
    'interpolate',
    ['linear'],
    [
      'coalesce',
      ['get', 'sizeIdx'],
      1.5
    ],
    0,
    0.6,
    5,
    1.8
  ];
  if (jsonEncode(layout['icon-size']) == jsonEncode(want)) return false;
  layout['icon-size'] = want;
  layers[i]['layout'] = layout;
  return true;
}

/// Direction chevrons along the active route at trail zooms. The icon is
/// registered at runtime by `addCairnIcons` (poi_icons.dart).
Map<String, dynamic> routeArrowsLayer() => {
      'id': 'route-arrows',
      'type': 'symbol',
      'source': 'cairn-route',
      'minzoom': 14,
      'layout': {
        'symbol-placement': 'line',
        'symbol-spacing': 90,
        'icon-image': 'route-arrow',
        'icon-size': 0.55,
        'icon-allow-overlap': true,
        'icon-ignore-placement': true,
        'icon-rotation-alignment': 'map',
      },
    };

/// Like [ensureLayerAfter], but a layer with the same id that differs from
/// [layer] is replaced in place, so a later tweak to a Cairn-owned layer
/// reaches every style. Returns true when anything changed.
bool upsertLayerAfter(
  List<Map<String, dynamic>> layers,
  String afterId,
  Map<String, dynamic> layer,
) {
  final existing = layers.indexWhere((l) => l['id'] == layer['id']);
  if (existing >= 0) {
    if (jsonEncode(layers[existing]) == jsonEncode(layer)) return false;
    layers[existing] = layer;
    return true;
  }
  return ensureLayerAfter(layers, afterId, layer);
}

/// Inserts [layer] right after the layer [afterId] unless a layer with the
/// same id already exists. Returns true when it was added.
bool ensureLayerAfter(
  List<Map<String, dynamic>> layers,
  String afterId,
  Map<String, dynamic> layer,
) {
  if (layers.any((l) => l['id'] == layer['id'])) return false;
  final i = layers.indexWhere((l) => l['id'] == afterId);
  if (i < 0) return false;
  layers.insert(i + 1, layer);
  return true;
}

/// Turns a layer whose `line-dasharray` (and optionally `line-color`) is a
/// `["case", ["==", ["get", prop], true], whenTrue, whenFalse]` expression into
/// a solid base layer filtered to `prop != true` plus a dashed [variantId]
/// layer filtered to `prop == true`. Returns true when something changed.
bool splitDashLayer(
  List<Map<String, dynamic>> layers,
  String id,
  String variantId,
  String prop,
) {
  final i = layers.indexWhere((l) => l['id'] == id);
  if (i < 0) return false;
  final base = layers[i];
  final paint = (base['paint'] as Map?)?.cast<String, dynamic>();
  if (paint == null) return false;
  if (!_isCase(paint['line-dasharray'])) return false;

  layers.removeWhere((l) => l['id'] == variantId);

  final baseFilter = _and(base['filter'], [
    '!=',
    ['get', prop],
    true
  ]);
  final variantFilter = _and(base['filter'], [
    '==',
    ['get', prop],
    true
  ]);

  final basePaint = Map<String, dynamic>.from(paint)
    ..['line-color'] = _branch(paint['line-color'], false)
    ..remove('line-dasharray');
  final baseDash = _literal(_branch(paint['line-dasharray'], false));
  if (baseDash is List && !(baseDash.length == 2 && baseDash[1] == 0)) {
    basePaint['line-dasharray'] = baseDash;
  }
  final variantPaint = Map<String, dynamic>.from(paint)
    ..['line-color'] = _branch(paint['line-color'], true)
    ..['line-dasharray'] = _literal(_branch(paint['line-dasharray'], true));

  final variant = Map<String, dynamic>.from(base)
    ..['id'] = variantId
    ..['filter'] = variantFilter
    ..['paint'] = variantPaint;
  base['filter'] = baseFilter;
  base['paint'] = basePaint;
  layers.insert(i + 1, variant);
  return true;
}

bool _isCase(Object? v) => v is List && v.length == 4 && v.first == 'case';

/// `whenTrue` or `whenFalse` of a two-branch case, or the value itself.
Object? _branch(Object? v, bool whenTrue) =>
    _isCase(v) ? (v as List)[whenTrue ? 2 : 3] : v;

Object? _literal(Object? v) =>
    v is List && v.length == 2 && v.first == 'literal' ? v[1] : v;

List<Object?> _and(Object? existing, List<Object?> clause) => [
      'all',
      if (existing != null) existing,
      clause,
    ];
