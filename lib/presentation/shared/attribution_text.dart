// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../l10n/app_localizations.dart';

/// Resolves an attribution l10n key to its text. Keeps the key list in
/// CairnMapStyle decoupled from the generated localizations.
String attributionText(AppLocalizations l10n, String key) => switch (key) {
      'attributionOsm' => l10n.attributionOsm,
      'attributionOpenFreeMap' => l10n.attributionOpenFreeMap,
      'attributionUsgs' => l10n.attributionUsgs,
      'attributionTerrain' => l10n.attributionTerrain,
      'attributionNifc' => l10n.attributionNifc,
      'attributionNws' => l10n.attributionNws,
      'attributionOpenMeteo' => l10n.attributionOpenMeteo,
      'attributionUsgs3dep' => l10n.attributionUsgs3dep,
      'attributionIgn' => l10n.attributionIgn,
      'attributionUsfs' => l10n.attributionUsfs,
      'attributionNoaa' => l10n.attributionNoaa,
      'attributionOsmGps' => l10n.attributionOsmGps,
      'attributionMapLibre' => l10n.attributionMapLibre,
      'attributionNominatim' => l10n.attributionNominatim,
      _ => key,
    };

/// A block of attribution lines for the Settings, Data sources page.
class AttributionText extends StatelessWidget {
  const AttributionText({required this.keys, super.key});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              attributionText(l10n, key),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
