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

## Status

Phases 0 through 9 code-complete, plus multi-device sync (client + accountless E2E server),
both API backends, a security audit, a design mockup canvas, and now (morning session) a
homelab deploy bundle, RevenueCat store wiring, on-device verification, and a public GitHub
push. `flutter analyze` clean, 115 tests, both flavors build.

### Morning session (done)

- **Pushed to GitHub, public**: https://github.com/AffluentMods/cairn (branch `main`, CI
  active). Secret-scanned tree and full history first: nothing sensitive is exposed;
  .gitignore covers keystores, .env, key.properties, debug-symbols, the seeded design payload.
- **Device-verified on the Pixel_3a API 36 emulator**: Map renders with hillshade (Rainier,
  Packwood, US-12), the three styles, controls, and the gold FAB; system light/dark theme
  switches live; Plan, Record (idle), and Library screens render in the dark hero look; real
  Overpass and USFS requests fire. Fixed a stat-tile overflow spotted on device. NOT yet
  exercised on device: live GPS recording, offline basemap download, two-device sync (need
  real GPS and a deployed server).
- **Backend deploy bundle**: `C:/Users/discr/StudioProjects/cairn-backend` (Postgres + sync +
  proxy + Caddy TLS, one `docker compose up -d --build`). See its DEPLOY.md for the exact
  homelab steps. `docker compose config` validates; the services' own suites pass (27 + 31).
- **RevenueCat**: F-Droid-clean store wiring (purchases_flutter is not a default dependency;
  tool/store_prebuild.sh swaps it in for the store build only), a Summit purchase sheet, and
  docs/REVENUECAT.md with the exact Play Console + RevenueCat + build steps.

## Phase R: navigation redesign (Addendum A) - in progress

Executing the addendum as its own phase before resuming the numbered phases.
Committed in slices; `flutter analyze` clean and 117 tests pass at each.

Done and verified on the Pixel_3a API 36 emulator:
- **4-tab IA**: Explore, Navigate, Saved, Activity (old map/plan/record/library moved
  with `git mv`; `git log --follow` intact). One MapLibre surface at a time via CairnMap.
- **Explore**: full map, search, layer button, and a "Trails in view" list from OSM/USFS
  names in the viewport (grouped, distance-sorted, gain loaded lazily), each a card with a
  USFS chip, length, gain, distance away, and a heart that saves to FavoriteTrails.
- **Navigate**: shared map with round buttons (Layers with overlay badge, Conditions, 3D,
  Directions, Undo, Clear, Locate), StatRow (F3: distance/gain/loss/time, statEmpty, arrow
  icons), Save and Start. Directions hands the trailhead to the user's own maps app.
- **Saved**: Routes / Trails / Offline tabs, Import GPX and Settings in the app bar.
- **Activity**: recordings list with month totals.
- **Layers (A5)**: six base maps (outdoors, topo, satellite, and new terrain, road, ign_plan)
  in a scrollable sheet (fixes the F1 overflow), Tilt and 3D rows, and an overlays list
  (radar, temperature, snow depth, slope, lidar hillshade, OSM GPS traces). Base-map switching
  verified (Outdoors to Topo). Overlay service URLs are best-effort pending device checks.
- **Schema v3**: FavoriteTrails and UserWaypoints via a v2 to v3 migration.
- **F2** trail styling fixed in all six styles; **F3** stat row done.

Also done and emulator-verified since: the trail detail heart + "Navigate this trail" (loads a
trail as the active route); the draggable Navigate sheet with the stat row, elevation profile,
and the Download button with the Download/Start swap by offline coverage; the edit-mode toolbar;
elevation-profile units; user waypoints (long-press or the add button, kind/name/note editor,
colored pins, tap to edit); the real 3D terrain WebView (bundled MapLibre GL JS, no Play
services); the dead l10n keys removed; LICENSES updated. The community APK is confirmed free of
Play services, Firebase, and billing.

Overlay raster tiles now render: MapLibre Native does not substitute `{bbox-epsg-3857}`, so the
ArcGIS overlays are served through an on-device localhost tile proxy (`tile_proxy.dart`, A5.3).
The slope-angle overlay (USGS 3DEP) is verified rendering on the emulator; the NWS weather
service URLs (radar/temperature/snow) are best-effort and may need per-service path checks
(API_NOTES).

Remaining follow-ups (documented, not blockers):
- User-waypoint route attachment: pins are standalone and export fine (GPX `<wpt>` includes all
  pins), but attaching one to a specific saved route needs the active-route id tracked, a small
  refactor left for later.
- Optional: before/after screenshots for F1 to F3 under docs/screens/phase-r/.

## Questions for you

Answer whenever. Nothing below blocked the build; each has a shipped default I chose.

1. **Name.** Kept "Cairn", package `cairn`, bundle id `com.affluentlabs.cairn`. You said you
   were unsure. Rename is a find-and-replace when you decide.
2. **Push to a public GitHub repo?** The spec says public from day one, but pushing is
   outward-facing so I did not create a remote or push. Say the word (and the org/repo name)
   and I will create it and push, with the CI workflow already in place.
3. **Sync + proxy hosting.** cairn-sync and cairn-proxy are built and tested but not deployed.
   Where do they go (your Linux box, same as zestssh-api)? Once deployed, put the sync URL in
   the app's sync screen and the proxy URL in Settings.
4. **Proxy API keys.** cairn-proxy needs AirNow, developer.nps.gov, and ridb.recreation.gov
   keys in its `.env`. Without them those routes return 503 and the app falls back to no-key
   sources.
5. **RevenueCat / store flavor.** The Summit gate is wired (community always unlocked), but
   the real purchase needs your RevenueCat account, product `cairn_summit_lifetime` (USD
   9.99), and a store-only, F-Droid-clean wiring of `purchases_flutter`. Deferred; see
   docs/DECISIONS.md.
6. **Summit feature split.** I used spec Section 12.4 (unlimited offline, water/campsite
   helpers, follow-route, AirNow monitor). Confirm before Play launch.
7. **Express 5 for the backends.** Both flag a transitive `qs` advisory via Express 4. Low
   risk (JSON bodies, not query strings). Bump at a maintenance window?
8. **On-device QA.** I cannot drive a phone here, so all device-only acceptance items are
   unverified (marked NEEDS DEVICE per phase): map rendering and 60fps, GPS recording and
   screen-off survival, real offline behavior, the MapLibre offline basemap download (may
   need the style served over http), and an end-to-end sync between two devices.
9. **Follow-route picker UI** and a live-track map on the Record screen are the two known
   feature gaps (the recording provider already supports follow-route; only the picker is
   missing). Small follow-ups.
10. **Design canvas.** A mockup of the five hero screens is published (link in the chat). It
   is my read of the spec's design system; tell me what to adjust and I will update it.
11. **Is follow-route mode free?** (Phase R / Addendum A9). Navigate's Start uses follow mode,
   which Section 12.4 gates behind Summit. Built ungated for now; the gate is not implemented
   until you answer. Needed before Phase 9. (Answered 2026-09-11: free for everyone.)
12. **Supply-chain hardening (propose only, from the security audit).** Pin the GitHub Actions
   in `.github/workflows/ci.yml` to commit SHAs, add Dependabot for pub and Actions, and an
   OSV scan step. Config-only, but it changes how CI behaves, so say yes and I will do it.
13. **`FLAG_SECURE` on the sync screen** (blocks screenshots of the sync passphrase). Small
   platform change; also propose-only from the audit.
14. **Place search goes straight to Nominatim** (on submit, 1 req/s, cached). Their policy
   tolerates small apps; if Cairn grows, route it through cairn-proxy. Fine to leave for now?
15. **Wide views load no new trails.** Explore fetches Overpass cells only when the view spans
   at most four z10 cells (about zoom 10 and closer); further out it draws what is cached and
   the list says "zoom in". Alternative: a "Load trails here" button at wide zooms. Keep the
   quiet default?
16. **Physical-phone pass still needed:** real GPS auto-pause and off-route, notification
   taps, multi-hour battery per hour, OEM battery prompts, real offline bundle download, 3D
   WebGL, and the X1.5 frame budgets. Everything above was verified on the Pixel 3a emulator.

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

## Multi-device sync (client)  (DONE, code complete)

E2E crypto (Argon2id, AES-256-GCM, DEK indirection, verification hash), tombstone +
newest-wins merge (DB v2), gather/restore, sync client matching the cairn-sync contract,
sync service (enable/join/sync/disconnect/purge), sync screen, credentials in secure
storage. 12 sync tests (merge cases, crypto round-trip, tombstone propagation, newest-wins).
NEEDS DEVICE: end-to-end against a live cairn-sync server.

## Phase 9: settings, entitlements, privacy, hardening  (DONE, code complete)

Full Settings screen (units, theme, default map, weights, terrain cache clear, sync, proxy
URL, data sources, privacy, licenses, version). Data sources and privacy pages (privacy from
a bundled asset). Summit entitlement gate: summitUnlockedProvider (community and debug always
unlocked), wired at the offline-region limit and the water helper; the map, trails, planner,
recording, fires, weather, and one offline region are never gated. docs/LICENSES.md (all
direct deps GPL-3 compatible). F-Droid metadata/en-US (descriptions, changelog, title).

Security checklist (spec Section 9.5), status here (device/APK-scan items marked):
- [x] usesCleartextTraffic=false; network security config blocks HTTP (strict main config,
      localhost-only debug override).
- [x] allowBackup=false.
- [x] Only the seven declared permissions; background location requested at recording start.
- [x] No API keys in the app (keyed sources go through the optional proxy).
- [x] Dio logging is debug-only and never logs URLs (they carry coordinates).
- [x] flutter_secure_storage for sync credentials; shared_preferences only for settings.
- [x] GPX deep-link import validates size (20 MB cap) and parses as XML before acting.
- [x] Sync is E2E encrypted; server stores only ciphertext + verification hashes.
- [ ] NEEDS RELEASE BUILD: --obfuscate --split-debug-info; strings scan of the release APK
      for keys; debuggable=false; apkanalyzer confirms no Play/Firebase in the community APK.
- [ ] NEEDS USER: RevenueCat wiring + flavor-clean purchases_flutter (store only).

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

## Fix Pass 1 (in progress)

Blocks all feature work (docs/cairn-fix-pass-1.md). Done so far:

- X1.3.5 location never blocks; X1.3.10 map loading state; X1.3.3 forest-road exclude + cap 30;
  X1.3.6/7 overlay maxzoom + below the first Cairn layer; X2.1 route framing; X2.4 sheet title.
- X1.3.1 off-UI compute (`lib/core/worker/geo_worker.dart`, a `GeoWorker.run` seam over
  `Isolate.run`): terrarium DEM tiles now decode via the engine codec plus a worker (was
  `package:image` on the UI isolate, the heaviest op); Overpass responses fetched as raw text and
  decoded + parsed in a worker; trails GeoJSON build/simplify, the nearby-trails list, and the
  whole snap-and-route pass plus route-stats math all run off the UI isolate. `package:image`
  dropped. `buildRoute` unit tested.

Verified: `flutter analyze` clean, `flutter test` 120 passing,
`flutter build apk --flavor community --debug` builds.

NEEDS DEVICE: re-run the locate/pan/Show route/Navigate/3D/overlay session on the physical phone
and confirm zero ANRs and no frame over 32 ms after the first second (X1.4 budgets). Blocked
earlier by an Overpass outage; retry when a mirror is up.

Remaining: X1.3.2 viewport pipeline (debounce + generation + cancellation), X1.3.4 GeoJSON hash +
cap, X1.3.8 crash/stall log + Diagnostics, X2.5 profile redraw, X2.2/2.6/2.7 section/follow/Show
route, X2.8 simulator, X1.3.9 + X3 3D, X4 theme system.

## Fix Pass 1 status (updated)

Done and verified on the emulator (x64) with live network and simulated location:

- X1.3.1 GeoWorker off-UI compute: trails load with no ANR (Trails in view shows real gain and
  distance). X1.3.2/4 viewport pipeline + GeoJSON hash/cap. X1.3.3 forest-road exclude + cap 30.
  X1.3.5 location never blocks. X1.3.6/7 overlay bounds + order. X1.3.8 crash/stall log +
  Diagnostics. X1.3.10 map loading state.
- X2.1 route framing (route drawn + framed with stats), X2.4 sheet title/stats, X2.5 elevation
  profile redraw (clean grade-colored line, single fill, gutter labels, no stripes), X2.7 Show
  route (bright highlight + Clear pill).
- X2.6 follow-mode core: on Start the camera follows the location puck heading-up
  (MyLocationTrackingMode.trackingCompass); an off-route drift fires one haptic; a Recenter pill
  reappears via onCameraTrackingDismissed. Follow verified with `adb emu geo fix`; the pill's
  pan-triggered appearance needs a real finger (synthetic `adb` swipes do not trigger the
  dismiss callback).
- X4.2/4.3 theme token system + seven built-ins + Appearance (live theme switch verified),
  X4.4 Theme Designer + custom themes, X4.5 nav bar/sheets/chips refresh, X4.1 inactive-tab
  reskin fix.
- X1.3.9 3D WebView disposed on close. X3 3D drapes the active base map + terrain + route +
  markers + fly-along. NOTE: 3D rendering is unverified on the CI emulator (its WebView has no
  WebGL); verify on the physical phone.

Remaining (best done with real-device GPS, or lower priority):

- X2.2 which-section logic (whole trail vs viewport section + 25%).
- X2.8 route simulator + LocationSource dev controls (would let follow mode be exercised without
  real GPS).
- X4.6 tool/check_theme_tokens.sh CI guard (needs the remaining semantic-color allowlist first;
  the reskin already works because chrome reads the ColorScheme/tokens).
- X1.5 re-run the full scripted session on the physical phone (the source of truth for maps,
  location, and performance).

## Fix Pass 1 status (final for this session)

All emulator-verifiable Fix Pass 1 work is done and committed. Added since the previous status:

- X2.2 "Navigate this trail" section logic (whole trail under 15 mi, else the viewport section
  + 25%, oriented to start nearest the user). Partial: the trailhead-within-500m preference and
  the from-to / start-far banners still need POI naming and Navigate plumbing.
- X2.8 LocationSource + route simulator + Settings > Developer toggle + docs/BUILDING.md.
  Verified end to end: with the toggle on, Start walks the loaded route and the camera follows.
- X4.6 tool/check_theme_tokens.sh CI guard (raw Color(0x in presentation), wired into CI.
- Ran dart format across the tree so the CI format gate passes; build_runner output is current.

Full local CI gate is green: SPDX, theme-token check, dart format, build_runner (no diff),
flutter analyze, flutter test (168).

Needs the physical phone (the source of truth) and is the only Fix Pass 1 work left:

- X1.5 re-run the scripted session on the phone (locate/pan/Show route/Navigate/3D/overlays;
  confirm the X1.4 budgets: cold start < 2.5 s, no frame > 32 ms after the first second,
  memory < 350 MB, zero ANRs).
- 3D rendering (emulator WebView has no WebGL) and the Recenter pill's pan-triggered appearance
  (synthetic swipes don't fire the MapLibre dismiss callback).

## Phase 6 recording engine, done properly (2026-09-11)

Driven by the spec audit's top gaps (a killed app ended the hike; no auto-pause; live gain from
raw GPS) and the AllTrails benchmark (docs/DECISIONS.md, "Phase 6 recording engine"):

- **Durable, service-owned recording.** `RecordingTaskHandler` (the foreground service isolate)
  reads a session file, runs the GPS through the pure `RecordingEngine`, appends every fix and
  pause transition to `files/recording/<id>.jsonl`, and streams snapshots to the UI. The main
  isolate ingests the log on Finish, on the next launch after Stop was pressed on the
  notification with the app gone, or as a recovered paused session when the service itself
  died. Notification: distance, active time, state, Pause/Resume and Stop buttons.
- **Engine** (`lib/domain/usecases/recording_engine.dart`, 10 unit tests): accuracy and jump
  gates, DEM gain via `.f32` terrain sidecars with a GPS-median fallback and re-anchoring, 5 m
  hysteresis, auto-pause 20 s / resume on movement, route projection with a windowed nearest
  search, distance and gain remaining, ETA scaled by the hiker's own pace, off-route 60 m for 30 s
  with accuracy gating, hysteresis and mute, arrival, and a replayable log.
- **Settings > Recording**: GPS accuracy profiles (Precise / Balanced / Saver), auto-pause,
  Saver below 20 percent, keep screen on, and a battery-optimization status row that opens the
  system page. Battery start/end per track (schema v5) shows as "%/h" on the track detail.
- **Navigate while recording**: a collapsible sheet (three headline numbers, route status,
  Pause/Finish; full stats, ETA, gain left, profile with a position dot, and Discard above the
  fold), an off-route banner with distance, an arrow back to the trail and Mute, a Finish confirm,
  a recovered-session note, a battery hint, and a zoom to 16 on Start.
- **Map fix**: MapLibre Native drops any layer whose `line-dasharray` is data-driven, so the
  `trails` and `route` layers never rendered on Android. Split into solid plus dashed variant
  layers in all six styles (`tool/patch_cairn_layers.dart`); the generator matches.

Verified on the Pixel 3a API 36 emulator with the route simulator: live stats, ETA, profile dot
and DEM elevation during recording; swipe-from-recents keeps the service counting and reopening
re-attaches to the live session; Pause and Stop from the notification with the app gone, and the
next launch files the hike into Activity with 297 DEM-tagged points; `am force-stop` mid-hike
then relaunch shows "Recording recovered" paused, Resume restarts the service from the log,
Finish saves (battery 100 to 100 via battery_plus). Gate: analyze clean, 186 tests, SPDX and
theme checks, dart format.

NEEDS DEVICE: real GPS fixes (accuracy gating, auto-pause on a real stop, off-route on a real
detour, the notification tap), a multi-hour battery figure per profile, and the OEM battery
optimization prompt on Samsung/OnePlus.

## Offline bundles and the app icon (2026-09-11)

- **Offline regions**: every `offlineAllowed` base map in the picker (localized labels, current
  map preselected), the default name localized, Delete frees the MapLibre regions by metadata,
  Resume / Retry on incomplete or failed cards, Refresh refetches trails, POIs, land, and terrain
  (forced past the TTL), and each card shows its map types, zoom range, and download date. Land
  boundaries are now part of every prefetch.
- **Route downloads** from Navigate are corridor bundles (z10 to z14 around the route, z15 to z16
  in a 1.5 km corridor), estimated up front and named after the route (`corridorBoxes`, tested).
- **App icon**: a drawn cairn (adaptive + monochrome + legacy) and a white status-bar icon for the
  recording notification, generated by `tool/make_icons.py` (Pillow), output committed.

NEEDS DEVICE: an actual multi-hundred-MB bundle download on a phone (the emulator can only prove
the flow), and the offline map render with the radio off.

## Trail detail sheet v2 (2026-09-11)

The sheet now describes the whole named trail (ways chained into one line, `chainWays`, tested):
difficulty band with the score and inputs in a tooltip, route type, SAC grade, visibility and
surface chips, a stat strip (length one way, DEM gain, loss, high point), Typical and Fit times,
the elevation profile, parking or a trailhead near the start, and the sights along the way from
cached OSM POIs. Search groups hits by trail name and uses the right hint. `trail_rating_test`
checks the difficulty bands against the AllTrails labels sampled in the benchmark.

Navigate rendering: the traveled path draws in teal above the gold route while recording (and
after re-attaching or recovering), and the route carries direction chevrons from z14 in every
style (`route-arrows`, icon drawn at runtime). The route status row says "Waiting for a good GPS
fix" until a fix good enough to judge has been projected, instead of a confident "On route".
In debug builds with the simulator on, the map draws its own puck at the simulated fix and
follows it, since the native puck can only show the device.

Small Tier 3 items closed: profile labels at 11 sp (the spec floor), a light haptic when a
waypoint pin lands, the 3D view's base-map attribution (compact, bottom left), the GPX export
named after the active route, the designer preview's Start label and the GPX import fallbacks
localized.

Spec audit gaps closed in this pass: "Open with Cairn" for .gpx files now works (native intent
channel, shared importer, deep linking off so the file URI never reaches the router; verified
on the emulator from the Files app chooser both cold and with the app running: the route lands
in Saved with the "1 imported" snackbar); elevation falls back to Open-Meteo and reports
unknown instead of a flat sea-level profile (tested); the Conditions button works with no
route (map center, "Conditions for this area", verified); CI's release build uses
`--obfuscate --split-debug-info`.

Fires, GPX pins and place search (spec Phases 2, 4 and 7): the WFIGS incident layer was checked
live and its field names have no `attr_` prefix, so every fire without a perimeter had been
showing without acres, containment or dates; the parser now reads both spellings, dedupes points
against perimeters by IRWIN id, and has fixtures in the live shape (`nifc_parse_test`, plus NWS
hourly and alert fixtures in `nws_parse_test`). Fires are tappable on Explore (card: name,
wildfire or prescribed burn, acres, containment, updated, discovered, behavior) and flame icons
scale with acres. "Open on InciWeb" resolves the incident's own page through InciWeb's RSS feed
(`inciweb_source_test`) instead of the home page; verified on the emulator (busy state on the
button, Chrome opens the incident page). GPX `<wpt>` pins import as user waypoints attached to
the route, with kinds mapped from type, symbol or name (`gpx_importer_test`, codec tests).
Explore search gained Nominatim places on submit (trails as you type, places on Search; tapping
a place frames it), verified on the emulator ("Gifford Pinchot National Forest" frames the
forest). Time-ago strings are now l10n keys.

Critical fix found in logcat during that verification: since Fix Pass 1 X1.3.1 the Overpass
parse ran through a closure built inside the repository method, which captured the repository
and its database, so `Isolate.run` refused it and no new map cell ever ingested trails or POIs
(only cells cached before that change worked, which is why every emulator pass over Goat Rocks
looked fine). The worker calls now live in top-level async variants next to the parsers,
GeoWorker falls back to inline work (counted) rather than failing, and `overpass_ingest_test`
covers both repositories end to end with a recorded response. Verified on the emulator by
panning to an area with no cached cells. With ingestion alive again, wide views turned out to
queue every z10 cell on screen (36 Overpass queries at the forest-wide zoom, uncancellable), so
Explore now fetches only when the view spans at most four cells, loads them center first, and
stops between cells when the view has moved on (`tile_order_test`, cancellation test). The
first fresh town (Leavenworth) also showed that `highway=footway` sidewalks and crossings were
drawn as trails; the query and parser now drop street furniture and schema v6 clears the cached
ones.

Route editor parity (spec Phase 3, Addendum A4.3): Redo joins Undo on the edit toolbar (both
disabled when empty, `edit_history_test`), a tap on the route line inserts a waypoint into that
leg (`edit_geometry_test`), and a long press on a waypoint number drags it (MapLibre draggable
symbols, the drop recomputes the route). The edit card's hint explains the three gestures.
User pins now draw on Explore and open their editor on tap.

Three map bugs surfaced while verifying the editor on the emulator: `MapLibreMap` captures
its tap and long-press callbacks once, so entering customize mode never changed what a tap
did (no waypoint could be added from a map created outside edit mode); waypoint numbers drawn
as symbol annotations never rendered on Android (Native rejects the manager's data-driven
`text-font`), so they are now images in a runtime layer; and Explore came back from Navigate
with no trails because its "already sent" signature survived the new map. All three fixed
(CairnMap delegates callbacks through its state; `waypointIconPng`; signatures reset on style
load).

Navigate now draws the cached trails under the route (shared `syncTrailsLayer`), so customizing
snaps to trails you can see. Spec items filled in: elevation sparklines on Saved route rows and
Activity track rows (Phase 4), the 3-day AQI sparkline (Phase 7), and camps along the route
with the wilderness reminder (Phase 8, `campsites_along_route_test`).

Climb pill: sustained climbs are found on the route profile (`findClimbs`, tested) and the
recording sheet shows "Climb: 0.4 mi and 320 ft to the top" while one is under way. Design
sweep of every screen on the emulator (layer sheet, conditions, waypoint editor, edit toolbar,
track detail, Saved tabs, Appearance, Theme Designer and color picker, Sync, Sources, Privacy,
Diagnostics, offline sheet): fixed the doubled "#" in the color picker's HEX field, the
conditions panel titled "Navigate" instead of the route, recordings drawn in the route color on
the track detail, the unstructured privacy text, and the incomplete sources list.

## Numbered phases 0-9: all implemented

Recorded here for accuracy (Phases 4-8 were built during the overnight and Phase R work but never
got their own PROGRESS entry). Every numbered phase is implemented in code, with unit tests:

- Phase 0 scaffold, 1 map core, 2 trails/POIs, 3 route planner, 9 settings/privacy: marked DONE above.
- Phase 4 GPX import/export + Library: `lib/data/gpx/` (gpx_codec, gpx_importer), share via
  share_plus; `gpx_codec_test`.
- Phase 5 offline regions: `offline_repository_impl`, `offline_estimate` + Navigate Download;
  `offline_estimate_test`.
- Phase 6 track recording: `recording_provider`, `recording_service` (foreground service),
  Naismith/Pandolf; `recording_test`. Extended in Fix Pass 1 with follow mode + the simulator.
- Phase 7 conditions overlays: NWS/NIFC/Open-Meteo sources, `overlay_registry` + the tile proxy,
  `water_along_route`; `water_along_route_test`.
- Phase 8 Affluent Labs proxy: `affluent_proxy_source` + the Settings "Data proxy URL".

Phase 10 and beyond is backlog and needs the user before starting (CLAUDE.md). On-device
acceptance of each phase on the physical phone is the remaining verification, tracked with the
Fix Pass 1 X1.5 scripted session.
