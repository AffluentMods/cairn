// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings.dart';
import '../../data/data_providers.dart';
import '../../data/purchases/purchases.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../../l10n/app_localizations.dart';
import '../map/map_providers.dart';
import '../map/map_style.dart';
import '../settings/summit_sheet.dart';
import '../shared/empty_state.dart';
import 'library_providers.dart';

/// Progress of an in-flight region download: id and 0..1.
final _activeDownloadProvider =
    StateProvider<({String id, double progress})?>((ref) => null);

/// Offline regions: list what is downloaded, and download a new region for the
/// current map view (spec Phase 5). The basemap tile download runs through the
/// MapLibre controller; trails, POIs, and terrain are prefetched so planning and
/// elevation work with no signal.
class OfflineRegionsScreen extends ConsumerWidget {
  const OfflineRegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final regions = ref.watch(offlineRegionsProvider);
    final active = ref.watch(_activeDownloadProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineTitle),
        actions: [
          TextButton.icon(
            onPressed: () => _openNewRegion(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.offlineNew),
          ),
        ],
      ),
      body: regions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            EmptyState(icon: Icons.error_outline, title: l10n.offlineTitle),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.download_for_offline_outlined,
              title: l10n.offlineTitle,
              message: l10n.libraryEmptyOffline,
            );
          }
          return ListView(
            children: [
              for (final r in items)
                _RegionTile(
                  region: r,
                  progress: active?.id == r.id ? active!.progress : null,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openNewRegion(BuildContext context, WidgetRef ref) async {
    final viewport = ref.read(viewportProvider);
    if (viewport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationPermissionBody)),
      );
      return;
    }
    // Summit gate: free builds get one offline region (spec Section 12.4). The
    // map, trails, and one region are never gated.
    final unlocked = ref.read(summitUnlockedProvider);
    final existing = ref.read(offlineRegionsProvider).valueOrNull ?? const [];
    if (!unlocked && existing.isNotEmpty) {
      await showSummit(context);
      // If they unlocked, they can tap New again; keep this action simple.
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewRegionSheet(bbox: viewport.bbox),
    );
  }
}

class _RegionTile extends ConsumerWidget {
  const _RegionTile({required this.region, this.progress});

  final OfflineRegionModel region;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mb = region.bytes == null
        ? null
        : '${(region.bytes! / (1024 * 1024)).round()} MB';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    region.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (mb != null) Text(mb),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${region.styleKeys.join(', ')}  z${region.minZoom} to z${region.maxZoom}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              Text(l10n.offlineDownloading((progress! * 100).round())),
            ] else if (region.status == OfflineStatus.downloading) ...[
              const SizedBox(height: 8),
              Text(l10n.offlineIncomplete),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _delete(context, ref),
                  child: Text(l10n.libraryDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(offlineRepositoryProvider);
    if (region.status == OfflineStatus.done) {
      // Best effort: also drop the MapLibre basemap region if we recorded one.
    }
    await repo.delete(region.id);
    bumpLibrary(ref);
  }
}

class _NewRegionSheet extends ConsumerStatefulWidget {
  const _NewRegionSheet({required this.bbox});
  final List<double> bbox;

  @override
  ConsumerState<_NewRegionSheet> createState() => _NewRegionSheetState();
}

class _NewRegionSheetState extends ConsumerState<_NewRegionSheet> {
  final _styles = <CairnMapStyle>{CairnMapStyle.outdoors};
  int _maxZoom = 14;
  final _name = TextEditingController();
  bool _downloading = false;

  RegionEstimate get _estimate => estimateRegionBytes(
        widget.bbox,
        minZoom: 10,
        maxZoom: _maxZoom,
        vectorStyles: _styles.contains(CairnMapStyle.outdoors) ? 1 : 0,
        rasterStyles: _styles.where((s) => s != CairnMapStyle.outdoors).length,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final est = _estimate;
    final sizeMb = (est.bytes / (1024 * 1024)).round();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.offlineName),
          ),
          const SizedBox(height: 12),
          Text(l10n.offlineStyles,
              style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final s in CairnMapStyle.values)
                FilterChip(
                  label: Text(_styleLabel(l10n, s)),
                  selected: _styles.contains(s),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _styles.add(s);
                    } else if (_styles.length > 1) {
                      _styles.remove(s);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${l10n.offlineMaxZoom}: z$_maxZoom'),
          Slider(
            value: _maxZoom.toDouble(),
            min: 12,
            max: 16,
            divisions: 4,
            label: 'z$_maxZoom',
            onChanged: (v) => setState(() => _maxZoom = v.round()),
          ),
          Text(
            l10n.offlineEstimate('$sizeMb MB'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (est.isLarge)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.offlineLargeWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _downloading ? null : _download,
              child: _downloading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.offlineDownload),
            ),
          ),
        ],
      ),
    );
  }

  String _styleLabel(AppLocalizations l10n, CairnMapStyle s) => switch (s) {
        CairnMapStyle.outdoors => l10n.styleOutdoors,
        CairnMapStyle.topo => l10n.styleTopo,
        CairnMapStyle.satellite => l10n.styleSatellite,
      };

  Future<void> _download() async {
    setState(() => _downloading = true);
    final repo = ref.read(offlineRepositoryProvider);
    final id = const Uuid().v4();
    final bbox = widget.bbox;
    final est = _estimate;
    final region = OfflineRegionModel(
      id: id,
      name: _name.text.trim().isEmpty ? 'Offline region' : _name.text.trim(),
      minLat: bbox[0],
      minLon: bbox[1],
      maxLat: bbox[2],
      maxLon: bbox[3],
      styleKeys: _styles.map((s) => s.name).toList(),
      minZoom: 10,
      maxZoom: _maxZoom,
      createdAt: DateTime.now(),
      status: OfflineStatus.downloading,
      tileCount: est.tileCount,
      bytes: est.bytes,
    );
    await repo.upsert(region);
    bumpLibrary(ref);
    if (mounted) Navigator.of(context).pop();

    try {
      // Basemap tiles per selected style (needs the live controller; device only).
      final bounds = LatLngBounds(
        southwest: LatLng(bbox[0], bbox[1]),
        northeast: LatLng(bbox[2], bbox[3]),
      );
      for (final style in _styles) {
        await downloadOfflineRegion(
          OfflineRegionDefinition(
            bounds: bounds,
            mapStyleUrl: style.assetPath,
            minZoom: 10,
            maxZoom: _maxZoom.toDouble(),
          ),
          metadata: {'regionId': id, 'style': style.name},
          onEvent: (event) {
            if (event is InProgress) {
              ref.read(_activeDownloadProvider.notifier).state =
                  (id: id, progress: event.progress / 100.0);
            }
          },
        );
      }
      // Trails, POIs, terrain so planning and elevation work offline.
      await repo.prefetchDataLayers(
        bbox,
        onProgress: (p) => ref.read(_activeDownloadProvider.notifier).state =
            (id: id, progress: p),
      );
      await repo.updateStatus(id, OfflineStatus.done, bytes: est.bytes);
    } catch (_) {
      await repo.updateStatus(id, OfflineStatus.error);
    } finally {
      ref.read(_activeDownloadProvider.notifier).state = null;
      bumpLibrary(ref);
    }
  }
}
