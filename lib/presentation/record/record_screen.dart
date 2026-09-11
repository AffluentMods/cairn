// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/units/unit_formatter.dart';
import '../shared/empty_state.dart';
import 'recording_provider.dart';
import 'widgets/live_stats_grid.dart';

/// The Record tab: start, pause, resume, finish a hike (spec Phase 6). Live
/// stats update while recording; the track saves to the Library on finish.
class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(recordingProvider.select((s) => s.status));
    return Scaffold(
      body: SafeArea(
        child: status == RecordingStatus.idle
            ? _IdleView(onStart: () => _startFlow(context, ref))
            : const _ActiveView(),
      ),
    );
  }

  Future<void> _startFlow(BuildContext context, WidgetRef ref) async {
    final defaultPack = ref.read(settingsProvider).defaultPackKg;
    final pack = await _promptPack(context, ref, defaultPack);
    if (pack == null) return; // cancelled
    await HapticFeedback.mediumImpact();
    await ref
        .read(recordingProvider.notifier)
        .start(packKg: pack.isNegative ? null : pack);
    if (pack > 0) {
      await ref.read(settingsProvider.notifier).setDefaultPackKg(pack);
    }
  }

  Future<double?> _promptPack(
    BuildContext context,
    WidgetRef ref,
    double? initial,
  ) {
    final l10n = context.l10n;
    final metric = ref.read(settingsProvider).units == UnitSystem.metric;
    final controller = TextEditingController(
      text: initial == null
          ? ''
          : (metric ? initial : initial / 0.45359237).toStringAsFixed(0),
    );
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recordPackPrompt),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: metric ? 'kg' : 'lb'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1.0), // start with no pack
            child: Text(l10n.genericSkip),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text) ?? 0;
              final kg = metric ? v : v * 0.45359237;
              Navigator.pop(context, kg);
            },
            child: Text(l10n.recordStart),
          ),
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.hiking_outlined,
            title: l10n.tabRecord,
            message: l10n.recordIdle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.recordStart),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveView extends ConsumerWidget {
  const _ActiveView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = ref.watch(unitFormatterProvider);
    final state = ref.watch(recordingProvider);
    final controller = ref.read(recordingProvider.notifier);
    final paused = state.status == RecordingStatus.paused;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const LiveStatsGrid(),
          const SizedBox(height: 12),
          if (paused)
            Text(l10n.recordAutoPaused,
                style: Theme.of(context).textTheme.titleSmall),
          if (state.followRouteId != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.onRoute ? Icons.check_circle : Icons.error_outline,
                  size: 16,
                  color: state.onRoute
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(state.onRoute ? l10n.recordOnRoute : l10n.recordOffRoute),
                if (state.distanceRemainingM != null) ...[
                  const SizedBox(width: 8),
                  Text(
                      l10n.recordToGo(fmt.distance(state.distanceRemainingM!))),
                ],
              ],
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await HapticFeedback.mediumImpact();
                    paused ? controller.resume() : controller.pause();
                  },
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? l10n.recordResume : l10n.recordPause),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _finish(context, ref),
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.recordFinish),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _discard(context, ref),
            child: Text(l10n.recordDiscard),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final fmt = ref.read(unitFormatterProvider);
    final messenger = ScaffoldMessenger.of(context);
    await HapticFeedback.mediumImpact();
    final summary = await ref.read(recordingProvider.notifier).finish();
    if (summary != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.recordSavedSummary(
              fmt.distance(summary.distanceM),
              fmt.elevationSigned(summary.gainM),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.recordDiscardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recordDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HapticFeedback.heavyImpact();
      await ref.read(recordingProvider.notifier).discard();
    }
  }
}
