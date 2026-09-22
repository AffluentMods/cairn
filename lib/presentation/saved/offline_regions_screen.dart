// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../data/data_providers.dart';
import '../../data/purchases/purchases.dart';
import '../../domain/models/offline_region.dart';
import '../../domain/usecases/offline_estimate.dart';
import '../map_common/basemaps/basemap_registry.dart';
import '../map_common/map_providers.dart';
import '../map_common/overlays/overlay_controller.dart';
import '../map_common/overlays/overlay_registry.dart';
import '../settings/summit_sheet.dart';
import '../shared/empty_state.dart';
import 'library_providers.dart';
import 'offline_download.dart';

/// Progress of an in-flight region job: id and 0..1. Shared with the Saved
/// tab's Offline list, which shows the same tiles.
final activeDownloadProvider =
    StateProvider<({String id, double progress})?>((ref) => null);

/// Offline regions: list what is downloaded, and download a new region for the
/// current map view (spec Phase 5). Basemap tiles run through MapLibre's
/// offline store; trails, POIs, land, and terrain are prefetched so planning,
/// conditions, and elevation work with no signal. Delete frees the tiles;
/// Resume finishes an interrupted download; Refresh refetches the data layers.
class OfflineRegionsScreen extends ConsumerWidget {
  const OfflineRegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final regions = ref.watch(offlineRegionsProvider);
    final active = ref.watch(activeDownloadProvider);

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
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final r in items)
                OfflineRegionTile(
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

class OfflineRegionTile extends ConsumerWidget {
  const OfflineRegionTile({required this.region, this.progress, super.key});

  final OfflineRegionModel region;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mb = region.bytes == null
        ? null
        : '${(region.bytes! / (1024 * 1024)).round()} MB';
    final styles = [
      for (final k in region.styleKeys) basemapByKey(k).label(l10n),
      for (final k in region.overlayKeys)
        if (overlayByKey(k) case final def?) def.label(l10n),
    ].join(', ');
    final busy = progress != null;
    final stale = !busy && region.status == OfflineStatus.downloading;
    final failed = !busy && region.status == OfflineStatus.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(region.name, style: theme.textTheme.titleMedium),
                ),
                if (mb != null) Text(mb, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$styles  ${l10n.offlineZoomRange(region.minZoom, region.maxZoom)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              l10n.offlineDownloadedOn(
                  DateFormat.yMMMd().format(region.createdAt)),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (busy) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(l10n.offlineDownloading((progress! * 100).round()),
                  style: theme.textTheme.bodySmall),
            ] else if (stale || failed) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    failed ? l10n.offlineFailed : l10n.offlineIncomplete,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!busy && region.status == OfflineStatus.done)
                  TextButton(
                    onPressed: () => _refresh(context, ref),
                    child: Text(l10n.offlineRefresh),
                  ),
                if (stale || failed)
                  TextButton(
                    onPressed: () => _resume(ref),
                    child:
                        Text(failed ? l10n.genericRetry : l10n.offlineResume),
                  ),
                TextButton(
                  onPressed: busy ? null : () => _delete(ref),
                  child: Text(l10n.libraryDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(WidgetRef ref) async {
    final repo = ref.read(offlineRepositoryProvider);
    await freeRegionTiles(region.id);
    await repo.delete(region.id);
    bumpLibrary(ref);
  }

  /// Finishes an interrupted or failed download. A route bundle's corridor
  /// boxes are not stored, so resuming one refetches its overview area.
  Future<void> _resume(WidgetRef ref) async {
    final repo = ref.read(offlineRepositoryProvider);
    final active = ref.read(activeDownloadProvider.notifier);
    final library = ref.read(libraryRefreshProvider.notifier);
    await repo.updateStatus(region.id, OfflineStatus.downloading);
    library.state++;
    active.state = (id: region.id, progress: 0);
    try {
      await downloadRegionBundle(
        repo,
        region,
        onProgress: (p) => active.state = (id: region.id, progress: p),
      );
    } finally {
      active.state = null;
      library.state++;
    }
  }

  /// Refetches trails, POIs, land, and terrain for the region so a bundle
  /// downloaded weeks ago carries current closures and reroutes.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(offlineRepositoryProvider);
    final active = ref.read(activeDownloadProvider.notifier);
    final library = ref.read(libraryRefreshProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(SnackBar(content: Text(context.l10n.offlineRefreshing)));
    active.state = (id: region.id, progress: 0);
    try {
      await repo.prefetchDataLayers(
        region.bbox,
        force: true,
        onProgress: (p) => active.state = (id: region.id, progress: p),
      );
    } finally {
      active.state = null;
      library.state++;
    }
  }
}

class _NewRegionSheet extends ConsumerStatefulWidget {
  const _NewRegionSheet({required this.bbox});
  final List<double> bbox;

  @override
  ConsumerState<_NewRegionSheet> createState() => _NewRegionSheetState();
}

class _NewRegionSheetState extends ConsumerState<_NewRegionSheet> {
  late final Set<String> _styles;
  late final Set<String> _overlays;
  int _maxZoom = 14;
  final _name = TextEditingController();
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    // Default to the base map on screen when it can be cached, and to the
    // overlays that are on the map right now (the live ones cannot be kept).
    final current = ref.read(basemapProvider);
    _styles = {current.offlineAllowed ? current.key : basemaps.first.key};
    _overlays = {
      for (final k in ref.read(overlayControllerProvider))
        if (overlayByKey(k)?.offlineAllowed ?? false) k,
    };
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  OfflineRegionModel _model(String id) => OfflineRegionModel(
        id: id,
        name: _name.text.trim().isEmpty
            ? context.l10n.offlineDefaultName
            : _name.text.trim(),
        minLat: widget.bbox[0],
        minLon: widget.bbox[1],
        maxLat: widget.bbox[2],
        maxLon: widget.bbox[3],
        styleKeys: _styles.toList(),
        overlayKeys: _overlays.toList(),
        minZoom: 10,
        maxZoom: _maxZoom,
        createdAt: DateTime.now(),
        status: OfflineStatus.downloading,
      );

  RegionEstimate get _estimate => estimateRegion(_model('estimate'));

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
            decoration: InputDecoration(
              labelText: l10n.offlineName,
              hintText: l10n.offlineDefaultName,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(l10n.offlineStyles,
              style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final b in basemaps.where((b) => b.offlineAllowed))
                FilterChip(
                  label: Text(b.label(l10n)),
                  selected: _styles.contains(b.key),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _styles.add(b.key);
                    } else if (_styles.length > 1) {
                      _styles.remove(b.key);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.offlineOverlays,
              style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final o in overlays.where((o) => o.offlineAllowed))
                FilterChip(
                  label: Text(o.label(l10n)),
                  selected: _overlays.contains(o.key),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _overlays.add(o.key);
                    } else {
                      _overlays.remove(o.key);
                    }
                  }),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.offlineAlwaysIncluded,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
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

  Future<void> _download() async {
    setState(() => _downloading = true);
    // Everything the job needs is read now: the sheet pops before the
    // download ends, and a disposed widget's ref cannot be used to refresh
    // the list (the region showed "Incomplete" until the next visit).
    final repo = ref.read(offlineRepositoryProvider);
    final active = ref.read(activeDownloadProvider.notifier);
    final library = ref.read(libraryRefreshProvider.notifier);
    final id = const Uuid().v4();
    final est = _estimate;
    final region = OfflineRegionModel(
      id: id,
      name: _model(id).name,
      minLat: widget.bbox[0],
      minLon: widget.bbox[1],
      maxLat: widget.bbox[2],
      maxLon: widget.bbox[3],
      styleKeys: _styles.toList(),
      overlayKeys: _overlays.toList(),
      minZoom: 10,
      maxZoom: _maxZoom,
      createdAt: DateTime.now(),
      status: OfflineStatus.downloading,
      tileCount: est.tileCount,
      bytes: est.bytes,
    );
    await repo.upsert(region);
    library.state++;
    if (mounted) Navigator.of(context).pop();

    active.state = (id: id, progress: 0);
    try {
      await downloadRegionBundle(
        repo,
        region,
        onProgress: (p) => active.state = (id: id, progress: p),
      );
    } finally {
      active.state = null;
      library.state++;
    }
  }
}
