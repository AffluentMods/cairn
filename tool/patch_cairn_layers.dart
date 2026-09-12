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
    final e = fixLabelFonts(style, layers);
    style['layers'] = layers;
    file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(style)}\n');
    stdout.writeln('${file.path}: trails ${a ? "split" : "ok"}, '
        'route ${b ? "split" : "ok"}, arrows ${c ? "added" : "ok"}, '
        'fire size ${d ? "set" : "ok"}, fonts ${e ? "fixed" : "ok"}');
  }
}

/// The glyph server every style can use for labels (the vector styles
/// already point here). The raster styles had none, and no Cairn symbol layer
/// named a `text-font`, so MapLibre asked for its default "Open Sans
/// Regular,Arial Unicode MS Regular" stack, got a 404, and never rendered the
/// POI layer at all (icons included). Returns true when changed.
const glyphsUrl = 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf';
const labelFont = ['Noto Sans Regular'];

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
    if (jsonEncode(layout['text-font']) == jsonEncode(labelFont)) continue;
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
