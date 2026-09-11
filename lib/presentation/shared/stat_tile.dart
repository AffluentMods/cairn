// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// A stat: a number in monospace tabular figures with a small caption below
/// (spec Section 9.4). No borders, 8 dp radius, calm.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.emphasized = false,
    super.key,
  });

  final String value;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle =
        emphasized ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.mono(
                numberStyle ?? const TextStyle(),
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
