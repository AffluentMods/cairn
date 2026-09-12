// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/models/offline_region.dart';
import '../../domain/repositories/offline_repository.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../map_common/basemaps/basemap_registry.dart';

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

/// Estimated bytes for a region: the bbox across its zoom range for each
/// style, plus the z15 to z16 corridor boxes when given.
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
  if (corridor.isEmpty) return base;
  final tiles = corridorTileCount(
    corridor,
    minZoom: corridorMinZoom,
    maxZoom: corridorMaxZoom,
  );
  final bytes = tiles * (vector * 25 * 1024 + raster * 60 * 1024);
  return RegionEstimate(
    tileCount: base.tileCount + tiles * region.styleKeys.length,
    bytes: base.bytes + bytes,
  );
}

/// Downloads the basemap tiles for [region] (every selected style across the
/// bbox and zoom range, plus trail-detail tiles along [corridor]) and then
/// prefetches trails, POIs, land, and terrain. Every MapLibre region carries
/// the Cairn region id in its metadata so Delete can free it. Marks the record
/// done or error; [onProgress] reports 0..1 across the whole job.
Future<bool> downloadRegionBundle(
  OfflineRepository repo,
  OfflineRegionModel region, {
  List<List<double>> corridor = const [],
  void Function(double progress)? onProgress,
}) async {
  await _raiseTileLimit();
  final styles = region.styleKeys.map(basemapByKey).toList();
  final jobs = styles.length * (1 + corridor.length);
  var done = 0;
  void report(double within) =>
      onProgress?.call(((done + within) / (jobs + 1)).clamp(0.0, 1.0));

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
    await repo.updateStatus(region.id, OfflineStatus.done);
    return true;
  } catch (_) {
    await repo.updateStatus(region.id, OfflineStatus.error);
    return false;
  }
}

/// Removes every MapLibre offline region downloaded for the Cairn region
/// [id], so Delete frees the tiles and not just the row.
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
}
