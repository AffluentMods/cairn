// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../data/data_providers.dart';
import '../../../domain/models/place_hit.dart';
import '../../../domain/models/trail.dart';
import '../../../l10n/app_localizations.dart';
import '../../map_common/map_providers.dart';
import '../nearby_trails_provider.dart';
import 'trail_detail_sheet.dart';

/// Search (spec Phase 2, Addendum A4.1): trail names over the cached ways as
/// you type (Drift LIKE), and places (towns, parks, trailheads) through
/// Nominatim when you press Search. Picking a trail opens its detail sheet;
/// picking a place flies the map there.
Future<void> showTrailSearch(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _TrailSearchSheet(),
  );
}

enum _PlacesState { idle, loading, done, failed }

class _TrailSearchSheet extends ConsumerStatefulWidget {
  const _TrailSearchSheet();

  @override
  ConsumerState<_TrailSearchSheet> createState() => _TrailSearchSheetState();
}

class _TrailSearchSheetState extends ConsumerState<_TrailSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Trail> _results = const [];
  bool _searching = false;

  _PlacesState _placesState = _PlacesState.idle;
  List<PlaceHit> _places = const [];

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(value));
    // A new query invalidates the old place results (no type-ahead: the
    // Nominatim policy forbids it, so places wait for Search).
    if (_placesState != _PlacesState.idle) {
      setState(() {
        _placesState = _PlacesState.idle;
        _places = const [];
      });
    }
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

  Future<void> _searchPlaces(String value) async {
    if (value.trim().length < 2) return;
    setState(() {
      _placesState = _PlacesState.loading;
      _places = const [];
    });
    final hits = await ref.read(nominatimSourceProvider).search(value);
    if (!mounted) return;
    setState(() {
      if (hits == null) {
        _placesState = _PlacesState.failed;
      } else {
        _placesState = _PlacesState.done;
        _places = hits;
      }
    });
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

  Future<void> _goTo(PlaceHit place) async {
    Navigator.of(context).pop();
    final c = ref.read(mapControllerProvider);
    if (c == null) return;
    try {
      if (place.isArea) {
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(place.south, place.west),
              northeast: LatLng(place.north, place.east),
            ),
            left: 48,
            top: 120,
            right: 48,
            bottom: 240,
          ),
        );
      } else {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(place.lat, place.lon), 13),
        );
      }
    } catch (_) {
      // The map is being rebuilt; the next idle refreshes what is in view.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final groups = _groups;
    final query = _controller.text.trim();

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            text,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        );
    Widget note(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Text(text, style: theme.textTheme.bodySmall),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _searchPlaces,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.travel_explore),
                    tooltip: l10n.searchPlacesAction,
                    onPressed: () => _searchPlaces(_controller.text),
                  ),
                  hintText: l10n.exploreSearchHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_searching || _placesState == _PlacesState.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  if (groups.isNotEmpty) header(l10n.searchTrailsHeader),
                  for (final ways in groups) _trailTile(ways, l10n),
                  if (query.length >= 2) header(l10n.searchPlacesHeader),
                  if (query.length >= 2)
                    switch (_placesState) {
                      _PlacesState.idle => note(l10n.searchPlacesHint),
                      _PlacesState.loading => const SizedBox.shrink(),
                      _PlacesState.failed => note(l10n.searchPlacesFailed),
                      _PlacesState.done when _places.isEmpty =>
                        note(l10n.searchPlacesNone),
                      _PlacesState.done => const SizedBox.shrink(),
                    },
                  for (final p in _places) _placeTile(p),
                  if (_places.isNotEmpty) note(l10n.searchPlacesAttribution),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trailTile(List<Trail> ways, AppLocalizations l10n) {
    final rep = ways.firstWhere(
      (w) => w.usfsNumber != null,
      orElse: () => ways.first,
    );
    final parts = <String>[
      if (rep.usfsNumber != null) l10n.trailUsfsNumber(rep.usfsNumber!),
      if (ways.length > 1) l10n.searchMatches(ways.length),
    ];
    return ListTile(
      leading: const Icon(Icons.route_outlined),
      title: Text(rep.name ?? l10n.trailUnnamed),
      subtitle: parts.isEmpty ? null : Text(parts.join('  ·  ')),
      onTap: () => _open(ways),
    );
  }

  Widget _placeTile(PlaceHit p) {
    // The display name repeats the place name first; show the rest.
    var detail = p.displayName;
    if (detail.startsWith(p.name)) {
      detail =
          detail.substring(p.name.length).replaceFirst(RegExp(r'^,\s*'), '');
    }
    return ListTile(
      leading: const Icon(Icons.place_outlined),
      title: Text(p.name),
      subtitle: detail.isEmpty
          ? null
          : Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _goTo(p),
    );
  }
}
