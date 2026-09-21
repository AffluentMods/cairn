// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Geographic coverage of a base map. Drives the "US only" / "France only"
/// chip in the layer sheet (Addendum A5.1).
enum Coverage { world, us, france }

/// One selectable base map: its bundled (or remote) style, its label, whether
/// the Phase 5 offline downloader may cache it, and its coverage.
class BasemapDef {
  const BasemapDef({
    required this.key,
    required this.assetPath,
    required this.label,
    required this.offlineAllowed,
    required this.coverage,
    this.vectorBase = false,
  });

  final String key;
  final String assetPath;
  final String Function(AppLocalizations) label;
  final bool offlineAllowed;
  final Coverage coverage;

  /// True for styles built on the OpenMapTiles `openmaptiles` vector source,
  /// which get Cairn's runtime base-map layers (summit labels). Raster styles
  /// (USGS Topo, imagery, IGN) carry their own labels.
  final bool vectorBase;
}

/// The base maps offered in the layer sheet (Addendum A5.1). Not const because
/// each label is a localization closure.
final basemaps = <BasemapDef>[
  BasemapDef(
    key: 'outdoors',
    assetPath: 'assets/map_styles/outdoors.json',
    label: (l) => l.styleOutdoors,
    offlineAllowed: true,
    coverage: Coverage.world,
    vectorBase: true,
  ),
  BasemapDef(
    key: 'topo',
    assetPath: 'assets/map_styles/topo.json',
    label: (l) => l.styleTopo,
    offlineAllowed: true,
    coverage: Coverage.us,
  ),
  BasemapDef(
    key: 'satellite',
    assetPath: 'assets/map_styles/satellite.json',
    label: (l) => l.styleSatellite,
    offlineAllowed: true,
    coverage: Coverage.us,
  ),
  BasemapDef(
    key: 'terrain',
    assetPath: 'assets/map_styles/terrain.json',
    label: (l) => l.styleTerrain,
    offlineAllowed: true,
    coverage: Coverage.world,
    vectorBase: true,
  ),
  BasemapDef(
    key: 'road',
    assetPath: 'assets/map_styles/road.json',
    label: (l) => l.styleRoad,
    offlineAllowed: true,
    coverage: Coverage.world,
    vectorBase: true,
  ),
  BasemapDef(
    key: 'ign_plan',
    assetPath: 'assets/map_styles/ign_plan.json',
    label: (l) => l.styleIgnPlan,
    offlineAllowed: false,
    coverage: Coverage.france,
  ),
];

BasemapDef basemapByKey(String key) =>
    basemaps.firstWhere((b) => b.key == key, orElse: () => basemaps.first);

const _kBasemapPref = 'map.basemap';

/// The selected base map, persisted by key. Seeds from the legacy
/// `settings.mapStyle` the first time so existing installs keep their choice.
class BasemapNotifier extends Notifier<BasemapDef> {
  @override
  BasemapDef build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_kBasemapPref);
    if (saved != null) return basemapByKey(saved);
    return basemapByKey(ref.read(settingsProvider).mapStyle.name);
  }

  Future<void> select(BasemapDef def) async {
    state = def;
    await ref.read(sharedPreferencesProvider).setString(_kBasemapPref, def.key);
  }
}

final basemapProvider =
    NotifierProvider<BasemapNotifier, BasemapDef>(BasemapNotifier.new);
