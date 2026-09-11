// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../core/l10n/l10n_ext.dart';

/// 3D terrain view (Addendum A5.2). The full WebView with bundled MapLibre GL
/// JS lands in the Phase R 3D slice; this placeholder keeps routing complete
/// and shows the offline message so nothing renders blank.
class Terrain3dScreen extends StatelessWidget {
  const Terrain3dScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1412),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.terrain, color: Colors.white24, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.nav3dNeedsConnection,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.navClose),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
