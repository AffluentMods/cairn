// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../data/data_providers.dart';
import '../../../domain/models/trail.dart';
import '../nearby_trails_provider.dart';
import 'trail_detail_sheet.dart';

/// Name search over cached trails (Drift LIKE, spec Phase 2). Opens a sheet with
/// a text field and live results; picking one opens its detail sheet.
Future<void> showTrailSearch(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _TrailSearchSheet(),
  );
}

class _TrailSearchSheet extends ConsumerStatefulWidget {
  const _TrailSearchSheet();

  @override
  ConsumerState<_TrailSearchSheet> createState() => _TrailSearchSheetState();
}

class _TrailSearchSheetState extends ConsumerState<_TrailSearchSheet> {
  Timer? _debounce;
  List<Trail> _results = const [];
  bool _searching = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(value));
  }

  Future<void> _run(String value) async {
    if (value.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    final hits = await ref.read(trailRepositoryProvider).searchByName(value);
    if (mounted) {
      setState(() {
        _results = hits;
        _searching = false;
      });
    }
  }

  /// One row per trail name: the hits are ways, and a trail is many ways.
  List<List<Trail>> get _groups {
    final byName = <String, List<Trail>>{};
    for (final t in _results) {
      (byName[t.name ?? ''] ??= []).add(t);
    }
    return byName.values.toList();
  }

  void _open(List<Trail> ways) {
    Navigator.of(context).pop();
    final geo = ways.first.geometry;
    final mid = geo.isEmpty ? const [0.0, 0.0] : geo[geo.length ~/ 2];
    showTrailDetail(context, buildNearbyTrail(ways, mid[0], mid[1]));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.exploreSearchHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: Builder(builder: (context) {
                final groups = _groups;
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final ways = groups[i];
                    final rep = ways.firstWhere(
                      (w) => w.usfsNumber != null,
                      orElse: () => ways.first,
                    );
                    final parts = <String>[
                      if (rep.usfsNumber != null)
                        l10n.trailUsfsNumber(rep.usfsNumber!),
                      if (ways.length > 1) l10n.searchMatches(ways.length),
                    ];
                    return ListTile(
                      leading: const Icon(Icons.route_outlined),
                      title: Text(rep.name ?? l10n.trailUnnamed),
                      subtitle:
                          parts.isEmpty ? null : Text(parts.join('  ·  ')),
                      onTap: () => _open(ways),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
