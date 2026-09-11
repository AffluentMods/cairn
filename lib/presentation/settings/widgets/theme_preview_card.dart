// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../../core/theme/cairn_theme.dart';

/// A live preview of a [CairnThemeSpec], rendered in that theme's own colors
/// (Fix Pass 1 X4.4): a mock surface with two text lines, an accent button, and
/// route and track dots. Used in the Appearance pickers and the Theme Designer.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.width = 150,
    super.key,
  });

  final CairnThemeSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? spec.accent : spec.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: spec.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: spec.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 7,
                    width: width * 0.55,
                    decoration: BoxDecoration(
                      color: spec.textPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 6,
                    width: width * 0.38,
                    decoration: BoxDecoration(
                      color: spec.textSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: spec.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check, size: 12, color: contrastOn(spec.accent)),
                ),
                const Spacer(),
                _dot(spec.route),
                const SizedBox(width: 4),
                _dot(spec.track),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    spec.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: spec.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, size: 16, color: spec.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
