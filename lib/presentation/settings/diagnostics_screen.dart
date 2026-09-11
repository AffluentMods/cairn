// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/diagnostics/crash_log.dart';
import '../../core/l10n/l10n_ext.dart';

/// Settings > Diagnostics (Fix Pass 1 X1.3.8): view, share, or clear the local
/// crash and stall log. The log lives only on the device and never holds
/// coordinates.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final log = CrashLog.instanceOrNull;
    final text = log?.readAll() ?? '';
    final empty = text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnosticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.diagnosticsShare,
            onPressed: empty ? null : () => Share.share(text),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.diagnosticsClear,
            onPressed: empty
                ? null
                : () async {
                    await log?.clear();
                    if (mounted) setState(() {});
                  },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.diagnosticsExplainer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Text(
                  l10n.diagnosticsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
