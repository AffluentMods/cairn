// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/fire_incident.dart';
import '../../shared/fire_format.dart';
import '../../shared/inciweb_button.dart';
import '../../shared/time_ago.dart';

/// The card for a fire tapped on the map (spec Phase 7): name, acres, percent
/// contained, discovery date, last update, fire behavior, and InciWeb.
Future<void> showFireCard(BuildContext context, FireIncident fire) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _FireCard(fire: fire),
  );
}

class _FireCard extends StatelessWidget {
  const _FireCard({required this.fire});
  final FireIncident fire;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = fire.prescribed ? AppColors.smoke : AppColors.fire;
    final facts = <String>[
      if (fire.acres != null) l10n.condFireAcres(formatAcres(fire.acres!)),
      if (fire.percentContained != null)
        l10n.condFireContained(fire.percentContained!),
      if (fire.modifiedAt != null)
        l10n.condUpdatedAgo(formatAgo(l10n, fire.modifiedAt!)),
    ];
    final discovered = fire.discoveredAt;
    final behavior = fire.behavior?.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(fire.name, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fire.prescribed ? l10n.firePrescribedBurn : l10n.fireWildfire,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(facts.join('  ·  '), style: theme.textTheme.bodyMedium),
            ],
            if (discovered != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.fireDiscovered(
                  DateFormat.MMMd().format(discovered.toLocal()),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (behavior != null && behavior.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.fireBehavior(behavior),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: InciwebButton(fire: fire, filled: true),
            ),
          ],
        ),
      ),
    );
  }
}
