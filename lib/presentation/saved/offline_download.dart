// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo/tile_math.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/repositories/offline_repository.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/overlays/overlay_registry.dart';
import '../map_common/overlays/tile_proxy.dart';

/// Base maps served as vector tiles (small); the rest are raster imagery.
const vectorBasemapKeys = {'outdoors', 'terrain', 'road'};

/// Trail-detail zooms fetched along a route corridor (docs/DECISIONS.md).
const corridorMinZoom = 15;
const corridorMaxZoom = 16;

/// Raised once per launch: MapLibre's default cap of 6,000 tiles is well
/// under a z10 to z16 route bundle.
bool _tileLimitRaised = false;

Future<void> _raiseTileLimit() async {
  if (_tileLimitRaised) return;
  _tileLimitRaised = true;
  try {
    await setOfflineTileCountLimit(250000);
  } catch (_) {
    // older platform or a test: the default limit still applies
  }
}

/// The zoom range an overlay is stored at for a region: the region's range
/// clipped to what the overlay draws (a z11-and-up overlay has no z10 tiles).
(int, int) overlayZoomRange(OverlayDef def, OfflineRegionModel region) => (
      math.max(def.minZoom, region.minZoom),
      math.min(def.maxZoom, region.maxZoom),
    );

/// Estimated bytes for a region: the bbox across its zoom range for each
/// style, the z15 to z16 corridor boxes when given, and each overlay across
/// its own zoom range.
RegionEstimate estimateRegion(
  OfflineRegionModel region, {
  List<List<double>> corridor = const [],
}) {
  final vector = region.styleKeys.where(vectorBasemapKeys.contains).length;
  final raster = region.styleKeys.length - vector;
  final base = estimateRegionBytes(
    region.bbox,
    minZoom: region.minZoom,
    maxZoom: region.maxZoom,
    vectorStyles: vector,
    rasterStyles: raster,
  );
  var tiles = base.tileCount;
  var bytes = base.bytes;
  if (corridor.isNotEmpty) {
    final n = corridorTileCount(
      corridor,
      minZoom: corridorMinZoom,
      maxZoom: corridorMaxZoom,
    );
    tiles += n * region.styleKeys.length;
    bytes += n * (vector * 25 * 1024 + raster * 60 * 1024);
  }
  for (final key in region.overlayKeys) {
    final def = overlayByKey(key);
    if (def == null) continue;
    final (minZ, maxZ) = overlayZoomRange(def, region);
    final n = overlayTileCount(region.bbox, minZoom: minZ, maxZoom: maxZ);
    tiles += n;
    bytes += n * overlayTileBytes;
  }
  return RegionEstimate(tileCount: tiles, bytes: bytes);
}

/// Downloads the basemap tiles for [region] (every selected style across the
/// bbox and zoom range, plus trail-detail tiles along [corridor]), prefetches
/// trails, roads, POIs, land, and terrain, then stores each chosen overlay's
/// tiles through the tile proxy. Every MapLibre region carries the Cairn
/// region id in its metadata so Delete can free it. Marks the record done or
/// error; [onProgress] reports 0..1 across the whole job.
Future<bool> downloadRegionBundle(
  OfflineRepository repo,
  OfflineRegionModel region, {
  List<List<double>> corridor = const [],
  void Function(double progress)? onProgress,
}) async {
  await _raiseTileLimit();
  final styles = region.styleKeys.map(basemapByKey).toList();
  final overlayDefs = [
    for (final key in region.overlayKeys)
      if (overlayByKey(key) case final def?) def,
  ];
  final jobs = styles.length * (1 + corridor.length) + 1 + overlayDefs.length;
  var done = 0;
  void report(double within) =>
      onProgress?.call(((done + within) / jobs).clamp(0.0, 1.0));

  try {
    for (final style in styles) {
      final boxes = [
        (region.bbox, region.minZoom, region.maxZoom),
        for (final c in corridor) (c, corridorMinZoom, corridorMaxZoom),
      ];
      for (var i = 0; i < boxes.length; i++) {
        final (bbox, minZ, maxZ) = boxes[i];
        await downloadOfflineRegion(
          OfflineRegionDefinition(
            bounds: LatLngBounds(
              southwest: LatLng(bbox[0], bbox[1]),
              northeast: LatLng(bbox[2], bbox[3]),
            ),
            mapStyleUrl: style.assetPath,
            minZoom: minZ.toDouble(),
            maxZoom: maxZ.toDouble(),
          ),
          metadata: {
            'regionId': region.id,
            'style': style.key,
            if (i > 0) 'corridor': i,
          },
          onEvent: (event) {
            if (event is InProgress) report(event.progress / 100.0);
          },
        );
        done++;
        report(0);
      }
    }
    await repo.prefetchDataLayers(region.bbox, onProgress: report);
    done++;
    report(0);
    for (final def in overlayDefs) {
      await downloadOverlayTiles(region, def, onProgress: report);
      done++;
      report(0);
    }
    await repo.updateStatus(region.id, OfflineStatus.done);
    return true;
  } catch (_) {
    await repo.updateStatus(region.id, OfflineStatus.error);
    return false;
  }
}

/// Stores one overlay's tiles for [region] through the tile proxy, zoom by
/// zoom. A tile that fails is skipped (Resume fetches it later); the proxy
/// keeps what arrived. [onProgress] reports 0..1 within this overlay.
Future<void> downloadOverlayTiles(
  OfflineRegionModel region,
  OverlayDef def, {
  void Function(double progress)? onProgress,
}) async {
  final template = def.tileUrl;
  if (template == null) return;
  final (minZ, maxZ) = overlayZoomRange(def, region);
  final tiles = <TileXY>[
    for (var z = minZ; z <= maxZ; z++) ...tilesForBbox(region.bbox, z),
  ];
  for (var i = 0; i < tiles.length; i++) {
    final t = tiles[i];
    await TileProxy.instance.downloadTile(
      regionId: region.id,
      key: def.key,
      template: template,
      z: t.z,
      x: t.x,
      y: t.y,
    );
    onProgress?.call((i + 1) / tiles.length);
  }
}

/// Removes every MapLibre offline region downloaded for the Cairn region
/// [id] and the overlay tiles stored for it, so Delete frees the tiles and
/// not just the row.
Future<void> freeRegionTiles(String id) async {
  try {
    final regions = await getListOfRegions();
    for (final r in regions) {
      if (r.metadata['regionId'] == id) {
        await deleteOfflineRegion(r.id);
      }
    }
  } catch (_) {
    // No MapLibre offline store (a test or a platform without one).
  }
  await TileProxy.instance.deleteRegionTiles(id);
}
