// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../data/data_providers.dart';
import '../../data/sources/inciweb_source.dart';
import '../../domain/models/fire_incident.dart';

/// "Open on InciWeb" for a fire (spec Phase 7). Looks the incident up in the
/// InciWeb feed first so the link lands on the fire's own page; falls back to
/// the InciWeb home page when the feed is unreachable or has no entry.
class InciwebButton extends ConsumerStatefulWidget {
  const InciwebButton({required this.fire, this.filled = false, super.key});

  final FireIncident fire;

  /// A full-width tonal button (the fire card) instead of a text button.
  final bool filled;

  @override
  ConsumerState<InciwebButton> createState() => _InciwebButtonState();
}

class _InciwebButtonState extends ConsumerState<InciwebButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    Uri url;
    try {
      url = await ref
          .read(inciwebSourceProvider)
          .incidentUrl(name: widget.fire.name, unitId: widget.fire.unitId)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      url = InciwebSource.homeUrl;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(context.l10n.condOpenInciweb);
    final Widget icon = _busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.open_in_new, size: 18);
    if (widget.filled) {
      return FilledButton.tonalIcon(
        onPressed: _busy ? null : _open,
        icon: icon,
        label: label,
      );
    }
    return TextButton.icon(
      onPressed: _busy ? null : _open,
      icon: icon,
      label: label,
    );
  }
}
