// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/l10n/l10n_ext.dart';
import '../shared/attribution_text.dart';

/// Data sources and attribution (spec Section 5, shown in Settings): every
/// base map, overlay, and data feed the app can reach, plus the map engine.
class AboutSourcesScreen extends StatelessWidget {
  const AboutSourcesScreen({super.key});

  static const _keys = [
    'attributionOpenFreeMap',
    'attributionOsm',
    'attributionUsgs',
    'attributionTerrain',
    'attributionUsgs3dep',
    'attributionIgn',
    'attributionUsfs',
    'attributionUsgsTrails',
    'attributionNifc',
    'attributionNws',
    'attributionNoaa',
    'attributionOpenMeteo',
    'attributionOsmGps',
    'attributionNominatim',
    'attributionMapLibre',
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
/// out of the code (spec Section 9, Phase 9). The asset is markdown-lite:
/// `# title`, `## heading`, `- bullet`, and paragraphs.
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: _render(context, snap.data!),
          );
        },
      ),
    );
  }

  List<Widget> _render(BuildContext context, String text) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final out = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('# ')) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(line.substring(2), style: theme.textTheme.headlineSmall),
        ));
      } else if (line.startsWith('## ')) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(line.substring(3), style: theme.textTheme.titleMedium),
        ));
      } else if (line.startsWith('- ')) {
        out.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: body),
              Expanded(child: Text(line.substring(2), style: body)),
            ],
          ),
        ));
      } else {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(line, style: body),
        ));
      }
    }
    return out;
  }
}
