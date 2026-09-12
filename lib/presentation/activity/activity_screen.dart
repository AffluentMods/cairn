// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../data/data_providers.dart';
import '../../domain/models/track.dart';
import '../saved/library_providers.dart';
import '../saved/profile_sparklines.dart';
import '../shared/empty_state.dart';

/// The Activity tab: recorded tracks with this-month totals and swipe to delete
/// (Addendum A1). Track detail opens at /activity/track/:id.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tracks = ref.watch(savedTracksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabActivity)),
      body: tracks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            EmptyState(icon: Icons.error_outline, title: l10n.activityEmpty),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.timeline,
              title: l10n.tabActivity,
              message: l10n.activityEmpty,
            );
          }
          return ListView(
            children: [
              _MonthTotals(tracks: items),
              for (final t in items)
                Dismissible(
                  key: ValueKey('track_${t.id}'),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBg(),
                  onDismissed: (_) => _deleteTrack(context, ref, t),
                  child: ListTile(
                    leading: const Icon(Icons.timeline_outlined),
                    title: Text(t.name),
                    subtitle: Text(_subtitle(ref, t)),
                    trailing: TrackSparkline(track: t),
                    onTap: () => context.push('/activity/track/${t.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _subtitle(WidgetRef ref, TrackSummary t) {
    final fmt = ref.read(unitFormatterProvider);
    final d = DateFormat.yMMMd().format(t.startedAt);
    return '$d  ${fmt.distance(t.distanceM)}  ${fmt.elevationSigned(t.gainM)}';
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

class _MonthTotals extends ConsumerWidget {
  const _MonthTotals({required this.tracks});
  final List<TrackSummary> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.read(unitFormatterProvider);
    final now = DateTime.now();
    final thisMonth = tracks.where(
      (t) => t.startedAt.year == now.year && t.startedAt.month == now.month,
    );
    if (thisMonth.isEmpty) return const SizedBox.shrink();
    var distance = 0.0;
    var gain = 0.0;
    for (final t in thisMonth) {
      distance += t.distanceM;
      gain += t.gainM;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activityThisMonth,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.activityTotals(
              fmt.distance(distance),
              fmt.elevationSigned(gain),
              thisMonth.length,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
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
