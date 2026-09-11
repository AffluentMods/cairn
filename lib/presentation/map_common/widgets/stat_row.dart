// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/theme/app_typography.dart';

/// The compact four-stat row for Navigate: distance, gain, loss, and estimated
/// time, each an icon plus a mono value (Addendum A4.2, fix F3). Values are
/// null when there is no route, and render as statEmpty. Distance never shows a
/// plus; gain and loss use arrow icons rather than plus/minus glyphs.
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    this.distance,
    this.gain,
    this.loss,
    this.time,
  });

  final String? distance;
  final String? gain;
  final String? loss;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = l10n.statEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _cell(context, Icons.straighten, distance ?? empty),
        _cell(context, Icons.north_east, gain ?? empty),
        _cell(context, Icons.south_east, loss ?? empty),
        _cell(context, Icons.schedule, time ?? empty),
      ],
    );
  }

  Widget _cell(BuildContext context, IconData icon, String value) {
    final theme = Theme.of(context);
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.mono(
                  theme.textTheme.bodyMedium ?? const TextStyle(),
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
