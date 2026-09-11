// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../data/gpx/gpx_codec.dart';
import '../../domain/models/route_plan.dart';
import '../../domain/models/track.dart';
import '../shared/empty_state.dart';
import 'library_providers.dart';

const _maxGpxBytes = 20 * 1024 * 1024;

/// The Library tab: saved routes, recorded tracks, and offline regions (spec
/// Section 3, Phase 4). Settings is reached from this app bar.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabLibrary),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: l10n.gpxImport,
              onPressed: () => _importGpx(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push('/library/settings'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.libraryRoutes),
              Tab(text: l10n.libraryTracks),
              Tab(text: l10n.libraryOffline),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_RoutesTab(), _TracksTab(), _OfflineTab()],
        ),
      ),
    );
  }

  Future<void> _importGpx(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) return;
      if (bytes.length > _maxGpxBytes) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.gpxImportFailed)));
        return;
      }
      final xml = utf8.decode(bytes, allowMalformed: true);
      final data = parseGpx(xml);
      if (data.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.gpxImportFailed)));
        return;
      }
      await ref.read(gpxImporterProvider).import(data, fallbackName: file.name);
      bumpLibrary(ref);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${data.tracks.length + data.routes.length} imported'),
        ),
      );
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gpxImportFailed)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gpxImportFailed)));
    }
  }
}

String _subtitle(WidgetRef ref, DateTime date, double distanceM, double gainM) {
  final fmt = ref.read(unitFormatterProvider);
  final d = DateFormat.yMMMd().format(date);
  return '$d  ${fmt.distance(distanceM)}  ${fmt.elevationSigned(gainM)}';
}

class _RoutesTab extends ConsumerWidget {
  const _RoutesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routes = ref.watch(savedRoutesProvider);
    return routes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        icon: Icons.error_outline,
        title: l10n.libraryEmptyRoutes,
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.route_outlined,
            title: l10n.libraryRoutes,
            message: l10n.libraryEmptyRoutes,
          );
        }
        return ListView(
          children: [
            for (final r in items)
              Dismissible(
                key: ValueKey('route_${r.id}'),
                direction: DismissDirection.endToStart,
                background: const _DeleteBg(),
                onDismissed: (_) => _deleteRoute(context, ref, r),
                child: ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: Text(r.name),
                  subtitle: Text(
                    _subtitle(ref, r.updatedAt, r.distanceM, r.gainM),
                  ),
                  onTap: () => context.push('/library/route/${r.id}'),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoute(
    BuildContext context,
    WidgetRef ref,
    SavedRoute route,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(routeRepositoryProvider).delete(route.id);
    bumpLibrary(ref);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.libraryDeleted),
        action: SnackBarAction(
          label: l10n.libraryUndo,
          onPressed: () async {
            await ref.read(routeRepositoryProvider).save(route);
            bumpLibrary(ref);
          },
        ),
      ),
    );
  }
}

class _TracksTab extends ConsumerWidget {
  const _TracksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tracks = ref.watch(savedTracksProvider);
    return tracks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        icon: Icons.error_outline,
        title: l10n.libraryEmptyTracks,
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.timeline_outlined,
            title: l10n.libraryTracks,
            message: l10n.libraryEmptyTracks,
          );
        }
        return ListView(
          children: [
            for (final t in items)
              Dismissible(
                key: ValueKey('track_${t.id}'),
                direction: DismissDirection.endToStart,
                background: const _DeleteBg(),
                onDismissed: (_) => _deleteTrack(context, ref, t),
                child: ListTile(
                  leading: const Icon(Icons.timeline_outlined),
                  title: Text(t.name),
                  subtitle: Text(
                    _subtitle(ref, t.startedAt, t.distanceM, t.gainM),
                  ),
                  onTap: () => context.push('/library/track/${t.id}'),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrack(
    BuildContext context,
    WidgetRef ref,
    TrackSummary track,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(trackRepositoryProvider);
    final points = await repo.pointsFor(track.id); // capture for undo
    await repo.deleteTrack(track.id);
    bumpLibrary(ref);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.libraryDeleted),
        action: SnackBarAction(
          label: l10n.libraryUndo,
          onPressed: () async {
            await repo.saveTrack(track, points);
            bumpLibrary(ref);
          },
        ),
      ),
    );
  }
}

class _OfflineTab extends ConsumerWidget {
  const _OfflineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.download_for_offline_outlined,
      title: l10n.libraryOffline,
      message: l10n.libraryEmptyOffline,
      action: FilledButton(
        onPressed: () => context.push('/library/offline'),
        child: Text(l10n.offlineNew),
      ),
    );
  }
}

class _DeleteBg extends StatelessWidget {
  const _DeleteBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline),
    );
  }
}
