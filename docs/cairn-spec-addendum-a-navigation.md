<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# CAIRN Spec Addendum A: Navigation Redesign, Map Types, Overlays

**Date:** 2026-09-11
**Applies to:** `docs/cairn-build-spec.md` (the main spec)
**Save as:** `docs/cairn-spec-addendum-a-navigation.md` and add this line to `CLAUDE.md`:
`- Read docs/cairn-spec-addendum-a-navigation.md after the main spec. Where they conflict, the addendum wins.`

---

## A0. How to apply this

1. This addendum supersedes the main spec in these places: Section 3 "Navigation", Section 6 `presentation/` layout, Section 9.6 mockups, the tab and library keys in Section 10, and the router skeleton in Phase 0.
2. Do this work now as its own phase, **Phase R**, before continuing the numbered phases. Commit `phase-r: navigation redesign`.
3. Do not redo finished phases. Move their code to the new locations in A2. Later phases keep their content but land in the new screens (mapping in A1).
4. Everything in A5 marked **Not buildable** stays out of the UI. Write each one into `docs/DECISIONS.md` with the reason given here, so nobody re-adds it.
5. Buttons whose feature belongs to an unfinished phase (Download needs Phase 5, Start needs Phase 6) are hidden, not disabled with "coming soon" copy. They appear when their phase lands.
6. All main spec rules still apply: l10n keys for every string, no em dashes, SPDX headers, no keys in the app, analyzer clean.

---

## A1. Tab structure

AllTrails uses Explore, For you, Navigate, Saved, Activity. Cairn uses four of them.

| New tab | Path | Purpose | Absorbs from main spec |
|---|---|---|---|
| Explore | `/explore` | Find trails: map, search, nearby trails list, trail detail sheet, save a trail | Map tab (Phases 1, 2, 7 map layers) |
| Navigate | `/navigate` | The active route: full map, layers, customize route, directions, waypoints, stats sheet with profile, Download and Start, live recording | Plan tab (Phase 3), Record tab (Phase 6), follow mode |
| Saved | `/saved` | Saved routes, saved trails, offline regions. App bar: Import GPX, Settings | Library Routes and Offline tabs (Phases 4, 5), Settings (Phase 9) |
| Activity | `/activity` | Recorded tracks, track detail, monthly totals | Library Tracks tab (Phases 4, 6) |

**Dropped:** "For you". It is an algorithmic feed and needs accounts and community data, both non-goals.

---

## A2. Repository layout changes

Replace `lib/presentation/map`, `plan`, `record`, `library` with:

```
lib/presentation/
├── shell/app_shell.dart
├── map_common/                         # shared by Explore and Navigate
│   ├── cairn_map.dart                  # MapLibreMap wrapper, mounts only when its tab is active
│   ├── camera_provider.dart            # shared camera, persisted
│   ├── basemaps/basemap_registry.dart  # A5.1
│   ├── overlays/overlay_registry.dart  # A5.3
│   ├── overlays/overlay_controller.dart
│   ├── layers/                         # moved from presentation/map/layers
│   └── widgets/
│       ├── layer_sheet.dart            # replaces layer_switcher_sheet.dart
│       ├── map_round_button.dart
│       ├── elevation_profile.dart      # moved from plan/widgets
│       └── stat_row.dart
├── explore/
│   ├── explore_screen.dart
│   ├── nearby_trails_provider.dart
│   └── widgets/
│       ├── trail_card.dart
│       ├── nearby_trails_sheet.dart
│       └── trail_detail_sheet.dart     # moved from map/widgets
├── navigate/
│   ├── navigate_screen.dart
│   ├── active_route_provider.dart
│   ├── route_editor_provider.dart      # moved from plan
│   ├── recording_service.dart          # moved from record
│   ├── recording_provider.dart         # moved from record
│   ├── directions_launcher.dart
│   ├── terrain_3d_screen.dart          # A5.2
│   └── widgets/
│       ├── navigate_sheet.dart
│       ├── edit_toolbar.dart
│       ├── waypoint_editor_sheet.dart
│       ├── live_stats_grid.dart        # moved from record/widgets
│       └── conditions_panel.dart       # moved from map/widgets
├── saved/
│   ├── saved_screen.dart
│   ├── route_detail_screen.dart
│   └── offline_regions_screen.dart
├── activity/
│   ├── activity_screen.dart
│   └── track_detail_screen.dart
├── settings/settings_screen.dart
└── shared/                             # unchanged
assets/web/
├── terrain3d.html
├── maplibre-gl.js                      # fetched by tool/fetch_maplibre_js.sh, pinned + SHA-256
└── maplibre-gl.css
assets/map_styles/
├── outdoors.json  topo.json  satellite.json   # existing
├── terrain.json                                # new, A5.1
├── road.json                                   # new, A5.1
└── ign_plan.json                               # new, A5.1
```

Use `git mv` so history follows the files.

---

## A3. Router and shell

`lib/core/router/app_router.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/explore',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/navigate', builder: (_, __) => const NavigateScreen(), routes: [
            GoRoute(
              path: '3d',
              parentNavigatorKey: rootNavigatorKey,
              builder: (_, __) => const Terrain3dScreen(),
            ),
          ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/saved', builder: (_, __) => const SavedScreen(), routes: [
            GoRoute(path: 'route/:id', builder: (_, s) => RouteDetailScreen(id: s.pathParameters['id']!)),
            GoRoute(path: 'offline', builder: (_, __) => const OfflineRegionsScreen()),
            GoRoute(
              path: 'settings',
              parentNavigatorKey: rootNavigatorKey,
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen(), routes: [
            GoRoute(path: 'track/:id', builder: (_, s) => TrackDetailScreen(id: s.pathParameters['id']!)),
          ]),
        ]),
      ],
    ),
  ],
);
```

Nav destinations (Material Symbols, outlined when inactive, filled when active): Explore `explore`, Navigate `navigation`, Saved `bookmark`, Activity `timeline`.

**One map at a time.** `indexedStack` keeps visited branches alive, which would keep two MapLibre GL surfaces in memory. `CairnMap` watches `shellIndexProvider` and only builds `MapLibreMap` when its own tab is current; otherwise it renders an empty `ColoredBox`. Camera lives in `cameraProvider` (persisted to SharedPreferences on camera idle) so each mount restores the same view. The recording service owns recording state, so unmounting the Navigate map during a recording loses nothing.

```dart
class CairnMap extends ConsumerWidget {
  const CairnMap({super.key, required this.tabIndex, required this.onCreated});
  final int tabIndex;
  final void Function(MapLibreMapController) onCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(shellIndexProvider) == tabIndex;
    if (!active) return const ColoredBox(color: Colors.transparent);
    final cam = ref.read(cameraProvider);
    final base = ref.watch(basemapProvider);
    return MapLibreMap(
      key: ValueKey(base.key),
      styleString: base.assetPath,
      initialCameraPosition: cam,
      onMapCreated: onCreated,
      onStyleLoadedCallback: () => ref.read(overlayControllerProvider.notifier).reinstall(),
      onCameraIdle: () => ref.read(cameraProvider.notifier).captureFromActiveController(),
      myLocationEnabled: true,
      compassEnabled: true,
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
```

---

## A4. Screens

### A4.1 Explore

```
┌───────────────────────────────────────────┐
│ ( 🔍 Search trails and places        )  ⧉ │  search field, layers button
│                                           │
│        (map: trails, POIs, fires)         │
│                                           │
│                                    (◉)    │  locate
│═══════════════════════════════════════════│
│ ━━  Trails in view                     12 │  nearby sheet, min 0.18
│ ┌───────────────────────────────────────┐ │
│ │ Snowgrass Trail           #96    ♡    │ │
│ │ 4.6 mi · +1,900 ft · T2 · 3.1 mi away │ │
│ └───────────────────────────────────────┘ │
│ ┌───────────────────────────────────────┐ │
│ │ Pacific Crest Trail   Section in view │ │
│ │ 11.2 mi · +2,480 ft · T3 · 0.4 mi away│ │
│ └───────────────────────────────────────┘ │
├───────────────────────────────────────────┤
│ Explore   Navigate   Saved   Activity     │
└───────────────────────────────────────────┘
```

**Nearby trails list** (`nearby_trails_provider.dart`), recomputed on camera idle, debounced 400 ms:

1. From Drift: `OsmRelations` with a `name`, plus named `OsmWays` grouped by `name` (ways of the same name that touch end to end form one trail). Only items intersecting the viewport.
2. Clip each trail's geometry to the viewport bbox expanded by 25%. If the full trail is longer than 30 mi (48 km), the card shows the clipped section and the chip `exploreSectionInView`.
3. Length from the clipped geometry. Gain from DEM via the Phase 3 elevation use case, computed lazily per card and cached in memory by `(trailId, bboxKey)`. Show a shimmer placeholder until ready.
4. Sort by distance from map center to the nearest point on the trail. Cap 50 cards.
5. Trail ids: `r<relationId>` or `w<firstWayId>`.

**Honesty note for the UI and README:** AllTrails lists curated named loops ("PCT, Muddy Meadows, and Highline Trail"). Those are editorial content. Cairn lists the trails that exist in OSM and USFS data. Loops come from Customize route or GPX import. Do not invent loop names.

**Trail detail sheet** (existing Phase 2 sheet, moved) gains: heart button (save/unsave to `FavoriteTrails`), and the primary action becomes `trailNavigate` ("Navigate this trail"), which sets `activeRouteProvider` to the clipped trail as a route and calls `context.go('/navigate')`. One gold element: the Navigate button.

**Search:** keep the Phase 2 search (local `LIKE` over cached names, then Nominatim). Results list overlays the map; tapping flies the camera there.

### A4.2 Navigate

```
┌───────────────────────────────────────────┐
│ 0   1   2 mi (scale bar)                  │
│                                     [⧉]²  │  layers, badge = active overlays
│                                     [☁]   │  conditions panel
│ [N]                                       │  compass (MapLibre, shows when rotated)
│                                           │
│ [∿]  customize route        (gold route)  │
│ [➤]  directions                     [3D]  │  3D view
│ [◉]  locate                         [📍]  │  add waypoint
│═══════════════════════════════════════════│
│ ━━                                        │
│ Goat Rocks loop                        ✕  │
│ ∿ 12.4 mi  ↗ 2,706 ft  ↘ 2,690 ft  ⏱ 6h 20m│
│ ┌───────────────────────────────────────┐ │
│ │ 7,880 ft      ╱╲                      │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓╱  ╲╲                    │ │  progress fill to scrubber or
│ │ ▓▓▓▓▓▓▓▓▓▓▓╱      ╲╲___      4,540 ft │ │  distance traveled
│ │ 0 mi            6.2 mi         12.4 mi│ │
│ └───────────────────────────────────────┘ │
│  [ ⤓ Download ]          [ ➤ Start ]      │  primary swaps, see below
├───────────────────────────────────────────┤
│ Explore   Navigate   Saved   Activity     │
└───────────────────────────────────────────┘
```

**Map controls** (`map_round_button.dart`): 52 dp circles, `inkRaised` fill in dark, `paperRaised` with border in light, icon in text primary. None of them are gold; the sheet's primary button owns the accent. Active toggles (Customize route while editing, Tilt) get a 2 dp larch outline, not a fill.

| Position | Button | Action |
|---|---|---|
| Right, top | Layers (badge with active overlay count) | Opens layer sheet (A5) |
| Right, below layers | Conditions | Opens the Phase 7 conditions panel for the active route, or for the map center if none |
| Left, middle | Customize route | Enters edit mode (A4.3) |
| Left | Directions | Drive to the trailhead in an external maps app (A4.4) |
| Left, bottom | Locate | Recenter; second tap toggles heading-up |
| Right, bottom | 3D view | Opens `/navigate/3d` (A5.2) |
| Right, bottom | Add waypoint | Drop a user waypoint (A4.5) |

**Sheet** (`navigate_sheet.dart`): `DraggableScrollableSheet`, `snap: true`, `snapSizes: [0.14, 0.45, 0.9]`, initial 0.45 when a route is loaded, 0.14 when empty.

| Snap | Content |
|---|---|
| 0.14 | Drag handle, route name, stat row (distance, gain, loss, est. time) |
| 0.45 | Plus elevation profile (140 dp) and the action row |
| 0.9 | Plus waypoint list (Phase 3), water list (Phase 8), user waypoints on this route, fire and weather badges (Phase 7), Export GPX |

**Sheet states:**

- **Empty:** title `navEmptyTitle`, body `navEmptyBody`, one gold button `navCustomizeRoute`.
- **Route loaded:** as mocked above.
- **Recording** (Phase 6): stat row becomes the live stats grid; profile fill tracks distance traveled along the route; action row becomes Pause (outlined) and Finish (gold). On-route or off-route line from Phase 6 follow mode sits above the grid.
- **Editing:** see A4.3.

**Primary action swap (single accent rule):**

```dart
final covered = ref.watch(routeOfflineCoverageProvider(route.id)); // true if an offline region contains the route bbox + 3 mi
final downloadBtn = covered
    ? TextButton.icon(onPressed: null, icon: const Icon(Icons.check), label: Text(context.l10n.navDownloaded))
    : FilledButton.icon(onPressed: () => ref.read(offlineRepositoryProvider).downloadForRoute(route, bufferM: 4828), icon: const Icon(Icons.download), label: Text(context.l10n.navDownload));
final startBtn = covered
    ? FilledButton.icon(onPressed: start, icon: const Icon(Icons.navigation), label: Text(context.l10n.navStart))
    : OutlinedButton.icon(onPressed: start, icon: const Icon(Icons.navigation), label: Text(context.l10n.navStart));
```

Not downloaded: Download is gold, Start is outlined. Downloaded: Download becomes a quiet "Downloaded" label, Start is gold. This nudges people to download before they lose signal without blocking them.

**Start** begins a Phase 6 recording linked to the active route in follow mode. See Q&A about the Summit gate.

**Elevation profile change:** keep the grade gradient on the line. Add a fill under the line from 0 to the scrubber position (planning) or distance traveled (recording) in `AppColors.larch` at 0.30 alpha, with the remainder at 0.08 alpha. Axis labels: min and max elevation on the right edge, 0, midpoint, and total distance along the bottom, all in JetBrains Mono.

### A4.3 Customize route (edit mode)

Tapping Customize route:

- Sheet collapses to 0.14 and shows live stats only.
- An `edit_toolbar.dart` bar slides in at the top: Undo, Redo, Clear, Done (Done is gold; the sheet has no gold element while editing).
- All Phase 3 behavior applies here unchanged: tap to add a snapped waypoint, long-press drag, tap a leg to insert, off-trail dashed legs, undo stack of 20.
- Done: if the route is new, show the name dialog and save (writes `Routes` + `RouteWaypoints`); then return to the Route loaded state.
- System back while editing with changes: confirm dialog `navDiscardChanges`.

### A4.4 Directions

Destination: the route's first waypoint, or the nearest OSM `highway=trailhead` or `amenity=parking` node within 500 m of it if one exists (use its name as the label).

`lib/presentation/navigate/directions_launcher.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
Future<bool> openDirections(double lat, double lon, {String? label}) async {
  final q = label == null ? '$lat,$lon' : '$lat,$lon(${Uri.encodeComponent(label)})';
  final geo = Uri.parse('geo:$lat,$lon?q=$q');
  if (await canLaunchUrl(geo)) {
    return launchUrl(geo, mode: LaunchMode.externalApplication);
  }
  final web = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lon'});
  return launchUrl(web, mode: LaunchMode.externalApplication);
}
```

The `geo:` intent lets the user's own maps app handle it (Organic Maps, OsmAnd, Google Maps). The web fallback is only a URL, not a Google library, so the community build stays F-Droid clean. Android 11+ package visibility: add to the manifest

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="geo"/>
  </intent>
</queries>
```

No in-app driving navigation. That remains a non-goal.

### A4.5 User waypoints and points of interest

These are pins the user drops (water, camp, hazard), separate from the numbered shaping waypoints that define a route.

- Add waypoint button, then tap the map. Long-press on the map also drops one (outside edit mode).
- `waypoint_editor_sheet.dart`: kind chips (water, camp, hazard, viewpoint, parking, note), name, note, "Attach to this route" switch (default on when a route is loaded), Save, Delete.
- Rendered from a new GeoJSON source `cairn-user-waypoints` with the Phase 1 sprite icons plus a `hazard` and `note` icon. Add the source and a symbol layer to every style JSON, above `pois`.
- Tap a pin to edit.
- GPX export includes attached user waypoints as `<wpt>` with `<name>`, `<desc>` (note), `<type>` (kind). GPX import already maps `<wpt>` to these (Phase 4).

---

## A5. Layer sheet

### Bug to fix first (seen on device)

The current layer switcher overflows by 108 px at the bottom. It is a `Column` inside a fixed-height modal. Rebuild as:

```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.35,
    maxChildSize: 0.92,
    builder: (context, scroll) => LayerSheet(scrollController: scroll),
  ),
);
```

`LayerSheet` is a `CustomScrollView` with three sections: Map type (a grid of 3 thumbnail tiles per row: 72 dp square preview image from `assets/map_previews/<key>.png`, label under), Overlays (switch rows, each with a subtitle for coverage and freshness), and a "3D view" row plus a "Tilt" switch. Widget test: pump at 360x640 logical px with `textScaler: TextScaler.linear(1.3)`; no overflow errors.

### A5.1 Map types (base maps)

`lib/presentation/map_common/basemaps/basemap_registry.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
class BasemapDef {
  const BasemapDef({
    required this.key,
    required this.assetPath,
    required this.label,
    required this.offlineAllowed,
    required this.coverage,
  });
  final String key;
  final String assetPath;
  final String Function(AppLocalizations) label;
  final bool offlineAllowed;   // false hides it from the Phase 5 style picker
  final Coverage coverage;     // world, us, france
}

final basemaps = <BasemapDef>[
  BasemapDef(key: 'outdoors', assetPath: 'assets/map_styles/outdoors.json', label: (l) => l.styleOutdoors, offlineAllowed: true, coverage: Coverage.world),
  BasemapDef(key: 'topo', assetPath: 'assets/map_styles/topo.json', label: (l) => l.styleTopo, offlineAllowed: true, coverage: Coverage.us),
  BasemapDef(key: 'satellite', assetPath: 'assets/map_styles/satellite.json', label: (l) => l.styleSatellite, offlineAllowed: true, coverage: Coverage.us),
  BasemapDef(key: 'terrain', assetPath: 'assets/map_styles/terrain.json', label: (l) => l.styleTerrain, offlineAllowed: true, coverage: Coverage.world),
  BasemapDef(key: 'road', assetPath: 'assets/map_styles/road.json', label: (l) => l.styleRoad, offlineAllowed: true, coverage: Coverage.world),
  BasemapDef(key: 'ign_plan', assetPath: 'assets/map_styles/ign_plan.json', label: (l) => l.styleIgnPlan, offlineAllowed: false, coverage: Coverage.france),
];
```

| Key | What it is | Source | Notes |
|---|---|---|---|
| `outdoors` | Cairn's trail-forward map (the "AllTrails style" slot) | Existing OpenFreeMap liberty + hillshade + Cairn layers | Do not name or style it after AllTrails. Tune per fix F2 below. |
| `topo` | USGS topo with contours | Existing | US only. |
| `satellite` | Imagery | Existing | US only for USGS imagery. |
| `terrain` | Muted base, strong relief | OpenFreeMap `positron` style snapshot (fetch with `tool/fetch_styles.dart` like liberty) + `terrain-dem` hillshade at exaggeration 0.6 + Cairn layers | Relief is the point; keep roads and labels light. |
| `road` | Road-first map | OpenFreeMap `bright` style snapshot + Cairn layers, no hillshade | For the drive in. |
| `ign_plan` | Plan IGN v2 (France) | Raster WMTS, `https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&FORMAT=image/png` | Open data, no key. Verify the URL and attribution text live and log in `docs/API_NOTES.md`. `offlineAllowed: false` until the Géoplateforme bulk-download terms are checked and written into DECISIONS. Attribution "© IGN". |

Style JSON for `ign_plan.json`: copy `topo.json`, replace the `usgs-topo` source with the IGN raster (`tileSize: 256`, `maxzoom: 18`), keep hillshade at 0.2, keep all `cairn-*` sources and layers.

Base maps with `Coverage.us` or `Coverage.france` show a subtitle chip (`coverageUsOnly`, `coverageFranceOnly`) in the grid.

**Not buildable, write into DECISIONS.md:**

| Requested | Why not |
|---|---|
| IGN SCAN 25 | Not open data. IGN excludes SCAN 25 from its open license because it contains third-party rights, and its license terms do not allow private individuals to download it, even for personal use. Needs a paid license. Plan IGN v2 covers France instead. |
| OS Great Britain (the Explorer/Leisure look) | OS Maps API needs an API key (the app ships no keys), the Leisure style is only served in British National Grid (EPSG:27700), which MapLibre's Web Mercator map cannot display, and premium zoom levels are paid with caching limits. Deferred to Phase 10: self-host OS Open Zoomstack (Open Government Licence) as PMTiles with OS's OGL "Open Outdoor" stylesheet from github.com/OrdnanceSurvey/OS-Vector-Tile-API-Stylesheets. It will not look like the paper Explorer map. |
| AllTrails map style | Proprietary. The `outdoors` style fills this slot. |

Other national topo maps (New Zealand LINZ, swisstopo, and so on) follow the same evaluation: open license, Web Mercator tiles, no key in the app, offline terms checked. Backlog only.

### A5.2 3D

**Constraint:** in `maplibre_gl`, `setTerrain` throws `UnsupportedError` on Android and iOS because MapLibre Native does not implement 3D terrain yet (it is on a feature branch upstream). Do not try to work around this inside the native map.

Two pieces instead:

1. **Tilt** switch (native, offline): animates camera pitch to 60° and bumps hillshade exaggeration by 0.15 on the active style. Off returns to pitch 0 and the original exaggeration. This is 2.5D, labeled `layersTilt`, not "3D".
2. **3D view** (WebView, online): `Terrain3dScreen` loads `assets/web/terrain3d.html` in `webview_flutter`, which runs bundled MapLibre GL JS with real terrain.

`assets/web/terrain3d.html` skeleton:

```html
<!doctype html>
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="maplibre-gl.css">
<style>html,body,#map{margin:0;height:100%;background:#0E1412}</style>
</head><body><div id="map"></div>
<script src="maplibre-gl.js"></script>
<script>
  let map;
  function init(opts) {
    map = new maplibregl.Map({
      container: 'map',
      style: opts.style,               // base map style object passed from Dart
      center: [opts.lon, opts.lat], zoom: opts.zoom, pitch: 65, bearing: opts.bearing,
      maxPitch: 85
    });
    map.on('load', () => {
      map.setTerrain({ source: 'terrain-dem', exaggeration: 1.3 });
      if (opts.route) {
        map.getSource('cairn-route').setData(opts.route);
      }
      CairnBridge.postMessage(JSON.stringify({ type: 'ready' }));
    });
    map.on('error', (e) => CairnBridge.postMessage(JSON.stringify({ type: 'error', message: String(e.error && e.error.message) })));
  }
</script>
</body></html>
```

Dart side:

- Load the active style JSON from assets, pass it with camera and active route GeoJSON via `controller.runJavaScript('init(${jsonEncode(opts)})')` after page load.
- `NavigationDelegate`: allow only the local asset page; `NavigationDecision.prevent` for everything else. JavaScript channel `CairnBridge` is the only bridge.
- If there is no connection (check `connectivity` via a failed HEAD to the terrain host, or the `error` message), show `nav3dNeedsConnection` over a dark background with a Close button. Never a blank WebView.
- Close returns to Navigate with the camera unchanged.
- `tool/fetch_maplibre_js.sh` downloads a pinned MapLibre GL JS release (BSD-3) from GitHub releases and verifies SHA-256. Both files are committed so F-Droid builds without network.
- `webview_flutter` is BSD-3 and uses the system WebView; no Play services. Note it in `docs/LICENSES.md`.
- When MapLibre Native ships terrain and `maplibre_gl` exposes it on Android, replace the WebView. Track this in DECISIONS.

### A5.3 Overlays

All overlays are added at runtime with `addSource`/`addLayer` when toggled on, and are **never** part of the style JSON files. Reason: Phase 5 `downloadOfflineRegion` downloads every source in the style; dynamic government map services must not be bulk-downloaded. Toggle state persists in SharedPreferences and is reinstalled on every style load.

`lib/presentation/map_common/overlays/overlay_registry.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
enum OverlaySourceKind { rasterTiles, cairnGeojson }

class OverlayDef {
  const OverlayDef({
    required this.key,
    required this.kind,
    required this.label,
    required this.subtitle,
    this.tileUrl,
    this.opacity = 0.7,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.refresh,
    this.attribution,
    this.coverage = Coverage.world,
    this.needsNetwork = true,
    this.disclaimer,
  });
  final String key;
  final OverlaySourceKind kind;
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) subtitle;
  final String? tileUrl;       // may contain {bbox-epsg-3857}
  final double opacity;
  final int minZoom, maxZoom;
  final Duration? refresh;     // rebuild the source with a cache-busting param on this interval
  final String Function(AppLocalizations)? attribution;
  final Coverage coverage;
  final bool needsNetwork;
  final String Function(AppLocalizations)? disclaimer;
}
```

ArcGIS dynamic services are consumed as MapLibre raster sources using the `{bbox-epsg-3857}` URL token:

```
MapServer:   {base}/export?bbox={bbox-epsg-3857}&bboxSR=3857&imageSR=3857&size=256,256&format=png32&transparent=true&layers=show:{layerIds}&f=image
ImageServer: {base}/exportImage?bbox={bbox-epsg-3857}&bboxSR=3857&imageSR=3857&size=256,256&format=png&renderingRule={urlEncodedJson}&f=image
```

If `maplibre_gl` on Android does not substitute `{bbox-epsg-3857}`, fall back to a Dart-side tile proxy: register a local `HttpServer` on `127.0.0.1` that converts `{z}/{x}/{y}` to a bbox with `tile_math.dart` and forwards the request. Log which path was needed in DECISIONS.

| Overlay | Source | Refresh | Coverage | Notes |
|---|---|---|---|---|
| Active fires | Existing Phase 7 NIFC layers (`cairn-fires`) | 15 min | US | `needsNetwork: false` (cached data shows with stale chip). |
| Precipitation radar | NOAA MRMS base reflectivity, `https://mapservices.weather.noaa.gov/eventdriven/rest/services/radar/radar_base_reflectivity/MapServer` (export, image sublayer) | 5 min | US | Current radar, not a forecast. Subtitle "Radar now". Check layer ids with `?f=json`. |
| Temperature forecast | NDFD temperature on `mapservices.weather.noaa.gov` | 1 h | US | Find the exact service by browsing `https://mapservices.weather.noaa.gov/raster/rest/services?f=json`; log path, layer ids, and legend in API_NOTES. If no usable temperature raster exists, drop this overlay and note it. |
| Snow depth | NOHRSC Snow Analysis, `https://mapservices.weather.noaa.gov/raster/rest/services/snow/NOHRSC_Snow_Analysis/MapServer` (snow depth layer) | 6 h | US | Modeled, 1 km, updated several times a day. Show legend from `/legend?f=json` in the sheet row when on. |
| Slope angle | USGS 3DEP, `https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer` with the "Slope Map" raster function | none | US | `disclaimer: slopeDisclaimer`. Show its legend. minZoom 11. |
| Lidar hillshade | USGS 3DEP ImageServer with "Hillshade Multidirectional" | none | US | Uses the best 3DEP resolution available at each spot (lidar-derived where it exists). opacity 0.5, blend over any base map. minZoom 11. |
| OSM GPS traces | `https://gps.tile.openstreetmap.org/lines/{z}/{x}/{y}.png` (verify live) | none | world | Substitute for the community heatmap. Public GPS traces uploaded to OpenStreetMap. Read the OSMF tile usage policy before shipping, log it in DECISIONS, send the Cairn User-Agent, no bulk download. |
| Trails, Water camps peaks, Wilderness and park boundaries | Existing Cairn GeoJSON layers | existing | existing | Move from the old sheet unchanged. `needsNetwork: false`. |

Hillshade moves from Overlays to a switch under Map type (it is part of the base styles).

When offline, network overlays stay toggleable but show the subtitle chip `overlayNeedsConnection` and their layers are removed from the map until a request succeeds.

Every active overlay adds its attribution to the map attribution control and to Settings > Data sources.

**Not buildable as requested, write into DECISIONS.md:**

| Requested | Why not | Substitute |
|---|---|---|
| Community heatmap | Requires a community of uploaded recordings, which needs accounts (non-goal). Strava's global heatmap requires login and its terms bar third-party use. | OSM GPS traces overlay (above). |
| Ground conditions | AllTrails derives it from user trail reports. Cairn has no reports. | "Recent weather" chip (below). Never call it trail conditions. |

**Recent weather chip** (trail detail sheet and Navigate sheet at 0.9): Open-Meteo forecast API with `past_days=3` for the trailhead: sum of `precipitation` and `snowfall`, minimum `temperature_2m`. Copy: `recentWeatherBody` plus the caption `recentWeatherNotReport`. Cache 60 min in `ConditionsCache`.

---

## A6. Fixes from current device screenshots

**F1. Layer sheet overflow.** Covered in A5.

**F2. Outdoors trails draw as thick white noodles at low zoom.** `trails-casing` has a fixed `line-width: 4` while `trails` interpolates from 1 at z10, so the pale casing dominates. `highway=track` (forest roads) is also styled as a trail, which fills every valley. Change in all style JSONs:

```json
{ "id": "trails-casing", "type": "line", "source": "cairn-trails", "minzoom": 12,
  "paint": { "line-color": "#F6F3EC",
             "line-width": ["interpolate", ["linear"], ["zoom"], 12, 2, 14, 4, 17, 6],
             "line-opacity": ["interpolate", ["linear"], ["zoom"], 12, 0.3, 14, 0.7] } },
{ "id": "tracks", "type": "line", "source": "cairn-trails", "minzoom": 12,
  "filter": ["==", ["get", "highway"], "track"],
  "paint": { "line-color": "#8C7A5E", "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.8, 16, 2],
             "line-dasharray": ["literal", [4, 2]] } },
{ "id": "trails", "type": "line", "source": "cairn-trails",
  "filter": ["!=", ["get", "highway"], "track"],
  "paint": { "...": "unchanged" } }
```

In dark theme on `outdoors` and `terrain`, change casing color to `#0E1412` at the same opacities. Acceptance: at z11 over Packwood the map reads as terrain with thin brown trail lines, not a white web.

**F3. Stats with no route.** The Plan stats show "0 ft" high point before any waypoint exists, and the four stats crowd each other. With no route, every value shows `statEmpty`. Use `stat_row.dart`: four `Expanded` children, value in JetBrains Mono `titleMedium`, caption in `labelSmall`, 8 dp between value and caption. Distance never shows `+`; gain and loss use arrow icons (↗ ↘) instead of `+`/`-` characters.

Put before and after screenshots for F1 to F3 in `docs/screens/phase-r/`.

---

## A7. Data model changes (Drift schema v2)

`lib/data/db/tables/favorite_trails.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
class FavoriteTrails extends Table {
  TextColumn get trailId => text()();              // "r123" or "w456"
  TextColumn get name => text()();
  RealColumn get centerLat => real()();
  RealColumn get centerLon => real()();
  RealColumn get lengthM => real().nullable()();
  DateTimeColumn get savedAt => dateTime()();
  @override Set<Column> get primaryKey => {trailId};
}
```

`lib/data/db/tables/user_waypoints.dart`:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later
class UserWaypoints extends Table {
  TextColumn get id => text()();                   // uuid
  TextColumn get kind => text()();                 // water, camp, hazard, viewpoint, parking, note
  TextColumn get name => text().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get routeId => text().nullable().references(Routes, #id)();
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
}
```

`app_database.dart`:

```dart
@DriftDatabase(tables: [
  OsmWays, OsmNodes, OsmRelations, Pois, CacheCells,
  Routes, RouteWaypoints, Tracks, TrackPoints, OfflineRegions, ConditionsCache,
  FavoriteTrails, UserWaypoints,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  @override int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(favoriteTrails);
            await m.createTable(userWaypoints);
          }
        },
      );
}
```

Add a Drift schema test: generate `drift_schemas/` with `dart run drift_dev make-migrations` and verify v1 to v2 upgrades without data loss.

Deleting a route sets `routeId` to null on its user waypoints (they stay as standalone pins) unless the user ticks "Also delete pins" in the confirm dialog.

---

## A8. Localization keys

Remove: `tabMap`, `tabPlan`, `tabRecord`, `tabLibrary`, `libraryRoutes`, `libraryTracks`, `libraryOffline`, `libraryEmptyRoutes`, `libraryEmptyTracks`, `layersTitle`, `layerHillshade` (replaced below). Update every call site in the same commit.

Add (each with an `@key` description entry in the real file):

```json
{
  "tabExplore": "Explore", "tabNavigate": "Navigate", "tabSaved": "Saved", "tabActivity": "Activity",

  "exploreSearchHint": "Search trails and places",
  "exploreTrailsInView": "Trails in view",
  "exploreSectionInView": "Section in view",
  "exploreDistanceAway": "{distance} away",
  "@exploreDistanceAway": { "placeholders": { "distance": { "type": "String" } } },
  "exploreEmpty": "No trails in this area yet. Zoom in or pan to load them.",
  "trailNavigate": "Navigate this trail",
  "trailSave": "Save trail", "trailUnsave": "Remove from saved",

  "navEmptyTitle": "No route loaded",
  "navEmptyBody": "Pick a trail in Explore, or draw your own.",
  "navCustomizeRoute": "Customize route",
  "navDirections": "Directions",
  "navDirectionsFailed": "No app could open directions.",
  "navDownload": "Download", "navDownloaded": "Downloaded",
  "navStart": "Start", "navDone": "Done", "navClear": "Clear",
  "navDiscardChanges": "Discard changes to this route?",
  "nav3dView": "3D view",
  "nav3dNeedsConnection": "3D view needs a connection. The flat map works offline.",
  "navClose": "Close",

  "layersMapType": "Map type", "layersOverlays": "Overlays",
  "layersHillshade": "Hillshade", "layersTilt": "Tilt",
  "styleTerrain": "Terrain", "styleRoad": "Road", "styleIgnPlan": "IGN Plan",
  "coverageUsOnly": "US only", "coverageFranceOnly": "France only",

  "overlayRadar": "Precipitation radar", "overlayRadarSubtitle": "Radar now, updates every 5 min",
  "overlayTemperature": "Temperature forecast", "overlayTemperatureSubtitle": "NWS forecast",
  "overlaySnowDepth": "Snow depth", "overlaySnowDepthSubtitle": "Modeled, updated several times a day",
  "overlaySlope": "Slope angle", "overlaySlopeSubtitle": "From USGS elevation data",
  "overlayLidarHillshade": "Lidar hillshade", "overlayLidarHillshadeSubtitle": "USGS 3DEP, best available resolution",
  "overlayGpsTraces": "OSM GPS traces", "overlayGpsTracesSubtitle": "Public traces uploaded to OpenStreetMap",
  "overlayNeedsConnection": "Needs a connection",
  "slopeDisclaimer": "Slope from USGS elevation data. Not an avalanche forecast.",

  "recentWeatherTitle": "Recent weather",
  "recentWeatherBody": "Last 3 days: {rain} rain, {snow} snow, low {temp}",
  "@recentWeatherBody": { "placeholders": { "rain": { "type": "String" }, "snow": { "type": "String" }, "temp": { "type": "String" } } },
  "recentWeatherNotReport": "Weather at the trailhead, not a trail report.",

  "waypointAdd": "Add waypoint", "waypointEdit": "Edit waypoint",
  "waypointKindWater": "Water", "waypointKindCamp": "Camp", "waypointKindHazard": "Hazard",
  "waypointKindViewpoint": "Viewpoint", "waypointKindParking": "Parking", "waypointKindNote": "Note",
  "waypointNameHint": "Name", "waypointNoteHint": "Note",
  "waypointAttachToRoute": "Attach to this route",
  "waypointDelete": "Delete waypoint",
  "routeDeletePinsToo": "Also delete pins on this route",

  "savedRoutes": "Routes", "savedTrails": "Trails", "savedOffline": "Offline",
  "savedEmptyRoutes": "No saved routes. Draw one in Navigate.",
  "savedEmptyTrails": "No saved trails. Tap the heart on a trail to keep it here.",

  "activityEmpty": "No recordings yet.",
  "activityThisMonth": "This month",
  "activityTotals": "{distance} · {gain} · {count} hikes",
  "@activityTotals": { "placeholders": { "distance": { "type": "String" }, "gain": { "type": "String" }, "count": { "type": "int" } } },

  "statEmpty": "--",

  "attributionIgn": "© IGN",
  "attributionNoaa": "Weather maps: NOAA National Weather Service",
  "attributionUsgs3dep": "Elevation: USGS 3DEP",
  "attributionOsmGps": "GPS traces © OpenStreetMap contributors"
}
```

The middle dot in `activityTotals` is intentional; it is not a dash.

---

## A9. Q&A additions (decisions made so you never stop)

| Question | Answer |
|---|---|
| Where does Settings live now? | Gear icon in the Saved app bar, next to Import GPX. |
| Start on a route uses follow mode, but Section 12.4 gates follow mode behind Summit. What do I build? | Build ungated. Gates are added in Phase 9 anyway. Add an open item to `docs/PROGRESS.md`: "User decision needed before Phase 9: is follow-route mode free?" Do not implement the gate until the user answers. |
| Two maps alive at once? | No. `CairnMap` mounts only for the active tab (A3). |
| `{bbox-epsg-3857}` does not work on Android? | Use the localhost tile proxy fallback in A5.3 and log it. |
| A NOAA or USGS service URL or layer id differs from this doc? | Trust the live service, log it in `docs/API_NOTES.md`. |
| An overlay service is down or removed? | Hide that overlay row, log it in PROGRESS, keep going. |
| Should base map previews be screenshots? | Yes: 72 dp square PNGs captured from the device at 46.52, -121.45 zoom 12 for each style (Chamonix 45.92, 6.87 zoom 12 for IGN), in `assets/map_previews/`. |
| Explore list for a huge relation like the PCT? | Clip to the viewport plus 25% and show "Section in view" (A4.1). |
| Include IGN SCAN 25 or OS GB behind a hidden flag? | No. Not in the code at all. DECISIONS entry only. |
| Does the 3D WebView need offline support? | No. Online only with a clear message. |
| Directions inside the app? | No. External app via `geo:` intent. |

---

## A10. Acceptance checklist (Phase R)

**Structure**
- [ ] Bottom nav shows Explore, Navigate, Saved, Activity with l10n labels; app opens on Explore
- [ ] Removed l10n keys have zero references (`grep -rn "tabMap\|libraryTracks" lib` returns nothing)
- [ ] Files moved with `git mv`; `git log --follow` works on `route_editor_provider.dart`
- [ ] Switching Explore and Navigate 20 times keeps memory under 350 MB (Android Studio profiler), and only one MapLibre surface exists at a time

**Explore**
- [ ] Panning to Goat Rocks lists Snowgrass Trail and a "Section in view" card for the PCT, sorted by distance from center
- [ ] Gain values fill in after load without blocking scroll
- [ ] Heart saves a trail; it appears in Saved > Trails and survives restart
- [ ] "Navigate this trail" opens Navigate with that trail loaded and the sheet at 0.45

**Navigate**
- [ ] Empty state shows `navEmptyTitle` and a gold Customize route button
- [ ] Route loaded: name, distance, gain, loss, est. time, profile with progress fill following the scrubber
- [ ] Download is gold and Start outlined when the route is not covered offline; after download they swap (skip until Phase 5 lands)
- [ ] Customize route: all Phase 3 acceptance items pass in edit mode; Done saves and returns to Route loaded
- [ ] Directions opens the installed maps app at the trailhead; with no maps app installed, the browser opens
- [ ] Add waypoint and long-press both drop a pin; edit, delete, attach to route all persist; exported GPX contains the pins as `<wpt>` with name, desc, type
- [ ] Recording (when Phase 6 exists): sheet shows live stats, Pause outlined, Finish gold, profile fill tracks distance traveled

**Layers**
- [ ] Layer sheet has no overflow at 360x640 with text scale 1.3 (widget test passes)
- [ ] All six base maps render; switching keeps camera; IGN Plan renders at Chamonix and shows "France only"
- [ ] Tilt switch pitches to 60° and back, works in airplane mode
- [ ] 3D view shows extruded terrain with the gold route; Close returns to the same camera; in airplane mode it shows `nav3dNeedsConnection`, never a blank page
- [ ] Each overlay toggles on and off, badge count matches, state survives restart and base map switches
- [ ] Radar source refreshes every 5 min (Dio or adb log shows the new cache-busting param)
- [ ] Slope and snow depth rows show their legend when on; slope row shows the disclaimer
- [ ] Airplane mode: network overlays show "Needs a connection" and do not spam failed requests (at most one retry per minute)
- [ ] A Phase 5 offline download (when it exists) makes zero requests to `mapservices.weather.noaa.gov`, `elevation.nationalmap.gov`, `gps.tile.openstreetmap.org`, or `data.geopf.fr`
- [ ] Attribution control and Settings > Data sources list every active overlay's attribution

**Fixes**
- [ ] F1, F2, F3 fixed with before and after screenshots in `docs/screens/phase-r/`

**Docs and hygiene**
- [ ] `docs/DECISIONS.md` has entries for: For you dropped, IGN SCAN 25 excluded, OS GB deferred, AllTrails style not copied, community heatmap substitute, ground conditions substitute, 3D via WebView, follow-route gate pending
- [ ] `docs/LICENSES.md` includes `webview_flutter` and MapLibre GL JS
- [ ] Drift v1 to v2 migration test passes
- [ ] `flutter analyze` clean, `flutter test` passes, `tool/check_spdx.sh` passes (including `terrain3d.html`)
- [ ] No em dashes: `grep -rn $'—' lib docs assets test tool` returns nothing
- [ ] Community flavor still builds with no Google libraries
- [ ] Commit `phase-r: navigation redesign`
