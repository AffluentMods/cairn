// SPDX-License-Identifier: GPL-3.0-or-later
import '../../../l10n/app_localizations.dart';
import '../basemaps/basemap_registry.dart' show Coverage;

/// How an overlay's tiles are produced.
enum OverlaySourceKind {
  /// A remote raster tile service (XYZ, or an ArcGIS export using the
  /// `{bbox-epsg-3857}` token that MapLibre substitutes per tile).
  rasterTiles,

  /// One of Cairn's own GeoJSON layers already present in the style, toggled by
  /// the existing map-layers mechanism rather than added here.
  cairnGeojson,
}

/// A toggleable map overlay (Addendum A5.3). Overlays are added at runtime with
/// addSource/addLayer when switched on, never baked into a style JSON, so the
/// Phase 5 offline downloader never bulk-fetches a dynamic government service.
class OverlayDef {
  const OverlayDef({
    required this.key,
    required this.kind,
    required this.label,
    required this.subtitle,
    this.tileUrl,
    this.opacity = 0.7,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.refresh,
    this.attribution,
    this.coverage = Coverage.world,
    this.needsNetwork = true,
    this.disclaimer,
  });

  final String key;
  final OverlaySourceKind kind;
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) subtitle;

  /// Raster tile template. May contain `{z}/{x}/{y}` or `{bbox-epsg-3857}`.
  final String? tileUrl;
  final double opacity;
  final int minZoom;
  final int maxZoom;

  /// If set, the source is reinstalled with a cache-busting parameter on this
  /// interval so live services (radar) refresh.
  final Duration? refresh;
  final String Function(AppLocalizations)? attribution;
  final Coverage coverage;
  final bool needsNetwork;
  final String Function(AppLocalizations)? disclaimer;

  String get sourceId => 'overlay-$key';
  String get layerId => 'overlay-$key-layer';
}

// ArcGIS ImageServer rendering rules, URL-encoded so the whole value can sit in
// a tile template. The exact rule names and NWS service paths are verified live
// on device and logged in docs/API_NOTES.md; until then these are best-effort.
const _slopeRule =
    '%7B%22rasterFunction%22%3A%22Slope%20Map%22%7D';
const _hillshadeRule =
    '%7B%22rasterFunction%22%3A%22Hillshade%20Multidirectional%22%7D';

const _arcgisExport =
    'bbox={bbox-epsg-3857}&bboxSR=3857&imageSR=3857&size=256,256'
    '&format=png32&transparent=true&f=image';

/// The raster overlays offered in the layer sheet. Cairn's own GeoJSON layers
/// (trails, water, boundaries, fires) stay on the existing map-layers toggle and
/// are not repeated here.
final overlays = <OverlayDef>[
  OverlayDef(
    key: 'radar',
    maxZoom: 10,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlayRadar,
    subtitle: (l) => l.overlayRadarSubtitle,
    tileUrl:
        'https://mapservices.weather.noaa.gov/eventdriven/rest/services/radar/'
        'radar_base_reflectivity/MapServer/export?$_arcgisExport',
    opacity: 0.6,
    refresh: const Duration(minutes: 5),
    attribution: (l) => l.attributionNoaa,
    coverage: Coverage.us,
  ),
  OverlayDef(
    key: 'temperature',
    maxZoom: 8,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlayTemperature,
    subtitle: (l) => l.overlayTemperatureSubtitle,
    tileUrl:
        'https://mapservices.weather.noaa.gov/raster/rest/services/NDFD/'
        'NDFD_temp/MapServer/export?layers=show:5&$_arcgisExport',
    opacity: 0.5,
    refresh: const Duration(hours: 1),
    attribution: (l) => l.attributionNoaa,
    coverage: Coverage.us,
  ),
  OverlayDef(
    key: 'snowDepth',
    maxZoom: 10,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlaySnowDepth,
    subtitle: (l) => l.overlaySnowDepthSubtitle,
    tileUrl:
        'https://mapservices.weather.noaa.gov/raster/rest/services/snow/'
        'NOHRSC_Snow_Analysis/MapServer/export?layers=show:0&$_arcgisExport',
    opacity: 0.6,
    refresh: const Duration(hours: 6),
    attribution: (l) => l.attributionNoaa,
    coverage: Coverage.us,
  ),
  OverlayDef(
    key: 'slope',
    maxZoom: 14,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlaySlope,
    subtitle: (l) => l.overlaySlopeSubtitle,
    tileUrl:
        'https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/'
        'ImageServer/exportImage?bbox={bbox-epsg-3857}&bboxSR=3857&imageSR=3857'
        '&size=256,256&format=png&renderingRule=$_slopeRule&f=image',
    opacity: 0.5,
    minZoom: 11,
    attribution: (l) => l.attributionUsgs3dep,
    coverage: Coverage.us,
    disclaimer: (l) => l.slopeDisclaimer,
  ),
  OverlayDef(
    key: 'lidarHillshade',
    maxZoom: 15,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlayLidarHillshade,
    subtitle: (l) => l.overlayLidarHillshadeSubtitle,
    tileUrl:
        'https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/'
        'ImageServer/exportImage?bbox={bbox-epsg-3857}&bboxSR=3857&imageSR=3857'
        '&size=256,256&format=png&renderingRule=$_hillshadeRule&f=image',
    opacity: 0.5,
    minZoom: 11,
    attribution: (l) => l.attributionUsgs3dep,
    coverage: Coverage.us,
  ),
  OverlayDef(
    key: 'gpsTraces',
    maxZoom: 16,
    kind: OverlaySourceKind.rasterTiles,
    label: (l) => l.overlayGpsTraces,
    subtitle: (l) => l.overlayGpsTracesSubtitle,
    tileUrl: 'https://gps.tile.openstreetmap.org/lines/{z}/{x}/{y}.png',
    opacity: 0.7,
    attribution: (l) => l.attributionOsmGps,
  ),
];

OverlayDef? overlayByKey(String key) {
  for (final o in overlays) {
    if (o.key == key) return o;
  }
  return null;
}
