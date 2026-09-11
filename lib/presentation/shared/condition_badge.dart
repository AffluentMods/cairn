// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// A condition pill: a colored dot on the left, short text, optionally tappable
/// for detail (spec Section 9.4).
class ConditionBadge extends StatelessWidget {
  const ConditionBadge({
    required this.color,
    required this.label,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Color color;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}
