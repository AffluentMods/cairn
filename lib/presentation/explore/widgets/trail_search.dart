// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../data/data_providers.dart';
import '../../../domain/models/trail.dart';
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
                  hintText: l10n.planNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final t = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.route_outlined),
                    title: Text(t.name ?? l10n.trailUnnamed),
                    subtitle: t.usfsNumber != null
                        ? Text(l10n.trailUsfsNumber(t.usfsNumber!))
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      showTrailDetail(context, t);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
