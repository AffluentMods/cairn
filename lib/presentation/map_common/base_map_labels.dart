// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/units/unit_formatter.dart';

/// The runtime layer that labels summits on the vector base maps.
const peaksLayerId = 'cairn-peaks';

/// The label a summit gets from the base map's `mountain_peak` layer: its name
/// over its elevation in the user's units, grouped ("Mount Aix\n7,766 ft").
/// A summit with no elevation in the data shows its name alone.
List<Object> peakLabelExpression(UnitFormatter units) {
  final field = units.units == UnitSystem.imperial ? 'ele_ft' : 'ele';
  final name = [
    'coalesce',
    ['get', 'name_en'],
    ['get', 'name'],
  ];
  return [
    'case',
    ['has', field],
    [
      'concat',
      name,
      '\n',
      [
        'number-format',
        ['get', field],
        {'max-fraction-digits': 0},
      ],
      ' ${units.elevationUnit}',
    ],
    name,
  ];
}

/// Named peaks and volcanoes, the summits a hiker navigates by. Saddles stay
/// with Cairn's own POIs.
const List<Object> peakFilter = [
  'all',
  [
    'match',
    ['get', 'class'],
    ['peak', 'volcano'],
    true,
    false,
  ],
  ['has', 'name'],
];

/// Adds (or replaces) the summit labels on a style that carries the
/// OpenMapTiles `openmaptiles` source: a small summit triangle with the name
/// and elevation, from zoom 9. Placed below the fire and POI symbols, which
/// win a collision, and ranked by the tile's own importance so the big peaks
/// survive at wide zooms. Not interactive, so a tap still reaches the trails
/// under a label. Added at runtime rather than baked into the style JSON so
/// the elevation follows the units setting.
Future<void> installPeakLabels(
  MapLibreMapController controller,
  UnitFormatter units,
) async {
  try {
    await controller.removeLayer(peaksLayerId);
  } catch (_) {
    // Not installed on this style yet.
  }
  await controller.addSymbolLayer(
    'openmaptiles',
    peaksLayerId,
    SymbolLayerProperties(
      iconImage: 'summit',
      iconSize: 1.0,
      textField: peakLabelExpression(units),
      textFont: const ['Noto Sans Regular'],
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        9,
        10,
        14,
        12,
      ],
      textAnchor: 'top',
      textOffset: const [0, 0.55],
      textMaxWidth: 8,
      textColor: '#4A3B2A',
      textHaloColor: 'rgba(255,255,255,0.85)',
      textHaloWidth: 1.4,
      symbolSortKey: const ['get', 'rank'],
    ),
    sourceLayer: 'mountain_peak',
    minzoom: 9,
    belowLayerId: 'fires-point',
    filter: peakFilter,
    enableInteraction: false,
  );
}
