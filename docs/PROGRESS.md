<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Cairn build progress

Running log. Newest first. Every phase ends with an entry: what shipped, what is verified,
what is next, what is blocked.

## Verification note (read this)

This build is happening on a Windows dev box with no physical Android phone driven by the
build agent. Device-only acceptance items (on-device rendering, GPS recording, foreground
service survival, real offline behavior) are marked **NEEDS DEVICE** and left for the user
to confirm. The verification gate used here is:

- `flutter analyze` clean
- `flutter test` green
- `dart run build_runner build` succeeds
- `flutter build apk --flavor community --debug` succeeds (full Android compile)

## Questions for you

Collected here so you can answer them all at once when you are back. See the bottom of this
file. Nothing below blocked the build; each has a shipped default.

---

## Backends (built in parallel, sibling repos)

- **cairn-sync** at `C:/Users/discr/StudioProjects/cairn-sync`: accountless E2E sync server
  (Node/Express/Postgres). 27 tests pass, AGPL-3.0, own git repo. Identity is a client
  sync_id bearer token; endpoints push/pull/status/verify-password/purge. This is the "Zest
  sync" the user asked for, adapted to Cairn's no-account rule. The Dart client (later phase)
  matches its wire contract exactly.
- **cairn-proxy** at `C:/Users/discr/StudioProjects/cairn-proxy`: key-holding cache proxy
  (Node/Express). 31 tests pass, AGPL-3.0, own git repo. Endpoints /v1/aqi, /v1/nps/alerts,
  /v1/ridb/facilities, /v1/restrictions.json, /v1/health. Consumed by Phase 8.
- Both flag the same transitive `qs` moderate advisory via Express 4 (query parser). Not a
  runtime risk here (JSON bodies, not query strings). A Question for you: bump to Express 5.

## Phase 3: route planner  (DONE, code complete)

Shipped, all unit tested: generic Dijkstra (binary heap), nearest-point-on-polyline,
snap-to-trail (40 m), leg routing over the OSM graph with tag penalties (informal 1.4,
difficult alpine 3.0, private impassable) and off-trail straight-line fallback, resample,
terrain terrarium tile source (fetch + disk cache + bilinear decode) and elevation
repository with gap-fill, compute_route_stats (20 m resample, hysteresis gain/loss,
Naismith/Langmuir time, profile). Plan screen: own MapLibre map, tap to add waypoints,
snapped route rendered gold (dashed off-trail), numbered waypoint symbols, live stats bar,
grade-colored elevation profile with a scrubber that drops a marker on the map, waypoint
list with swipe-to-delete, undo, clear, and save to Drift (name dialog). Route persistence
repository (save/load/delete + waypoints).

Tests: dijkstra (5-node fixture), nearest-point, routing (through shared node, same segment,
disconnected fallback), route penalties, route stats (hill gain/loss + profile), snap
in/out of range. 69 tests total, analyze clean.
NEEDS DEVICE: the Goat Rocks distance/gain acceptance (needs live Overpass + terrain tiles
and a device), profile-scrubber-to-map-marker interaction, dragging a waypoint (add/delete/
undo shipped; drag and mid-leg insert are follow-ups noted below).

## Phase 2: trails and POIs  (DONE)

Shipped: pure Overpass parser (ways, graph nodes, relations, POIs) with a captured real
fixture test (Goat Rocks: PCT, Old Cascade Crest, Bypass Trail #97); Overpass HTTP source
with mirror fallback; USFS ArcGIS source; Drift-backed trail and POI repositories with z10
cell caching (30-day TTL), bbox queries, and name search (Drift LIKE, tested in-memory);
best-effort name-based USFS enrichment; runtime-generated POI/fire map icons; trails and POI
GeoJSON layers fed per viewport (debounced) with Douglas-Peucker simplification at low zoom;
trail detail sheet (name, USFS chip, segment length, surface, SAC grade); trail name search
sheet; non-blocking offline banner. Analyze clean, 51 tests, community APK builds.
NEEDS DEVICE: on-device trail render latency, tap-to-open sheet, airplane-mode render.

## Phase 1: map core  (DONE, committed 6452563)

See commit. NEEDS DEVICE: on-device 60fps pan/rotate/tilt, hillshade at z11+, puck recenter.

## Phase 0: scaffold  (DONE, committed a90444f)

Verified: `flutter analyze` clean, `flutter test` 44 passing (geo + units + widget smoke),
`flutter build apk --flavor community --debug` built (193 MB debug APK), `flutter build apk
--flavor store --debug --dart-define=CAIRN_STORE=true` built, `tool/check_spdx.sh` passes.
NEEDS DEVICE: on-device render of the shell, live system-theme switch (both themes compile
and are wired to ThemeMode.system).

Beyond Phase 0, the pure-Dart geo core (Phases 1/3/7 foundation) is done and unit tested:
haversine, tile math, terrarium decode + bilinear, Douglas-Peucker, gain/loss hysteresis
(corrected from the spec's buggy snippet), Naismith/Langmuir time, NOAA solar (verified to
~30 s against api.sunrise-sunset.org), Meeus moon, and the SI-to-display UnitFormatter.

## Phase 0 detail (as built)

Shipped:
- `flutter create` Android project, org com.affluentlabs, package cairn.
- pubspec with the full Section 4 dependency set (resolved; 155 deps). Added `cryptography`
  for sync. Deferred `purchases_flutter` to Phase 9 (see DECISIONS).
- Android: community/store flavors, minSdk 26, targetSdk 35, buildConfig STORE_BUILD,
  release signing via key.properties with debug fallback.
- Manifest: full permission set, foreground service (location), GPX intent filter,
  allowBackup=false, cleartext disabled, network security config (strict release, localhost
  debug override).
- Root config: l10n.yaml, analysis_options.yaml (generated files excluded, strict casts),
  .gitignore hardened for keystores/symbols/env.
- Repo hygiene: LICENSE (GPL-3.0), README, CONTRIBUTING, SECURITY, CLAUDE.md, docs/*,
  .github issue templates and CI, assets/LICENSE.
- l10n starter app_en.arb, l10n extension, theme (dark and light), router, app shell with 4
  tabs and placeholder screens, SPDX check script.

Verified: (updated as the phase closes)

Next: Phase 1 map core.
