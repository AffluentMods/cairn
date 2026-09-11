// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/l10n/l10n_ext.dart';
import '../shared/attribution_text.dart';

/// Data sources and attribution (spec Section 5, shown in Settings).
class AboutSourcesScreen extends StatelessWidget {
  const AboutSourcesScreen({super.key});

  static const _keys = [
    'attributionOpenFreeMap',
    'attributionOsm',
    'attributionUsgs',
    'attributionTerrain',
    'attributionNifc',
    'attributionNws',
    'attributionOpenMeteo',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSources)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [AttributionText(keys: _keys)],
      ),
    );
  }
}

/// The privacy statement, loaded from a bundled asset so it stays editable and
/// out of the code (spec Section 9, Phase 9).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacy)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/data/privacy.txt'),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              snap.data!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}
