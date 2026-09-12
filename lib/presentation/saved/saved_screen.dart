// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../domain/models/route_plan.dart';
import '../shared/empty_state.dart';
import 'gpx_import.dart';
import 'library_providers.dart';

/// The Saved tab (Addendum A1): saved routes, saved trails, and offline regions.
/// The app bar carries Import GPX and Settings.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabSaved),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: l10n.gpxImport,
              onPressed: () => _importGpx(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push('/saved/settings'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.savedRoutes),
              Tab(text: l10n.savedTrails),
              Tab(text: l10n.savedOffline),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_RoutesTab(), _TrailsTab(), _OfflineTab()],
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
      await importGpxBytes(
        ref,
        bytes: bytes,
        name: file.name,
        l10n: l10n,
        messenger: messenger,
      );
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
      error: (_, __) =>
          EmptyState(icon: Icons.error_outline, title: l10n.savedEmptyRoutes),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.route_outlined,
            title: l10n.savedRoutes,
            message: l10n.savedEmptyRoutes,
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
                  subtitle:
                      Text(_subtitle(ref, r.updatedAt, r.distanceM, r.gainM)),
                  onTap: () => context.push('/saved/route/${r.id}'),
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

class _TrailsTab extends ConsumerWidget {
  const _TrailsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final saved = ref.watch(savedTrailListProvider);
    return saved.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          EmptyState(icon: Icons.error_outline, title: l10n.savedTrails),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border,
            title: l10n.savedTrails,
            message: l10n.savedEmptyTrails,
          );
        }
        return ListView(
          children: [
            for (final t in items)
              Dismissible(
                key: ValueKey('fav_${t.trailId}'),
                direction: DismissDirection.endToStart,
                background: const _DeleteBg(),
                onDismissed: (_) =>
                    ref.read(favoritesRepositoryProvider).remove(t.trailId),
                child: ListTile(
                  leading: const Icon(Icons.favorite),
                  title: Text(t.name),
                  subtitle:
                      t.lengthM == null ? null : Text(fmt.distance(t.lengthM!)),
                ),
              ),
          ],
        );
      },
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
      title: l10n.savedOffline,
      message: l10n.libraryEmptyOffline,
      action: FilledButton(
        onPressed: () => context.push('/saved/offline'),
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
