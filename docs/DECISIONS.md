<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Decisions made without the user

One line each, with the reason. Per the spec: when a choice is not pre-answered, pick the
option that ships fastest and record it here.

## Phase 0

- **Deferred `purchases_flutter` out of `pubspec.yaml`.** Reason: it is Phase 9 only and
  gated, and pulling it in as a normal dependency links Google Play Billing into the
  community APK, which F-Droid rejects. The entitlement layer ships now as an abstraction
  with a no-op (always entitled) implementation; the real RevenueCat wiring plus a
  flavor-clean separation (a store-only Gradle dependency, not a pub dependency) is a Phase 9
  task that also needs the user's RevenueCat account and product ids.
- **Added `cryptography: ^2.7.0`.** Reason: the multi-device sync the user asked for needs
  Argon2id key derivation and AES-256-GCM. Pure-Dart, cross-platform, no native Google libs,
  so the community flavor stays F-Droid clean.
- **targetSdk 35, compileSdk 35, minSdk 26.** Reason: spec says minSdk 26 and "current Play
  requirement (35)". SDK 35 is installed.
- **Generated files (`*.g.dart`, `*.freezed.dart`) are committed and excluded from analysis.**
  Reason: keeps CI able to analyze without running codegen, and keeps analyzer output clean
  since generated style is not ours to lint.
- **Dropped `require_trailing_commas`; enforce `dart format` in CI instead.** Reason: the
  spec listed the lint, but Dart 3.7+ shipped a new formatter that manages commas itself, so
  the lint and `dart format` fight (format wraps a call without a trailing comma, the lint
  then flags it). The modern equivalent is to let the formatter be the authority: CI runs
  `dart format --set-exit-if-changed`, which enforces the same consistency the lint intended.
  Strict casts and strict raw types stay on.
- **Manual Riverpod providers, not `@riverpod` codegen.** Reason: fewer build_runner cycles
  and faster iteration during the build. freezed, drift, and json_serializable still use
  codegen. The generator remains a dev dependency if we want it later.
- **OSM ids stored as `integer()` (native 64-bit int), not `int64()`/BigInt.** Reason: Cairn
  is mobile only (spec Q&A), where Dart int and SQLite INTEGER are 64-bit and current OSM ids
  are far below 2^53. Avoids BigInt friction across the codebase.
- **USFS trail enrichment is name-based, not geometry/proximity.** Reason: the spec's
  proximity-match-in-an-isolate is heavy and network dependent; a cheap name match ships now
  and is non-blocking. A geometry match is a later improvement (tracked in API_NOTES).

## Sync server (addition beyond the spec's Phase 0 to 9)

- **Built an accountless, end-to-end encrypted sync server (`cairn-sync/`), modeled on Zest
  sync.** Reason: the user explicitly asked for "a backend sync server similar to my Zest
  sync." Cairn's hard rule is "no account, ever," so the identity is a client-generated
  random sync id (an opaque bearer token), not an email or password account: no Firebase, no
  Stripe. The blob model, optimistic concurrency, write-verification gate, quotas, and the
  tombstone plus newest-wins merge follow ZestSSH exactly. Sync is optional and off by
  default; the app is fully functional offline without it. AGPL-3.0-or-later, same as the
  proxy.

## Phase R (navigation redesign, Addendum A)

- **No community or user-generated content (reviews, photos, star ratings), now or in Phase R.**
  Reason: the user chose this after weighing it. It keeps the "No account" promise and avoids
  the moderation, legal (photo/CSAM), cost, and cold-start burden, while preserving Cairn's
  differentiation (conditions, not social). The only future opening, and only if the app
  becomes popular, is an optional sign-in scoped to trail-condition comments. Not built now.
- **Dropped the "For you" tab.** Reason: an algorithmic feed needs accounts and community data,
  both non-goals. Nav is Explore, Navigate, Saved, Activity.
- **IGN SCAN 25 excluded entirely (not even a hidden flag).** Reason: not open data; IGN's open
  license excludes SCAN 25 (third-party rights) and bars private download even for personal
  use. Needs a paid license, and the app ships no keys. Plan IGN v2 covers France instead.
- **OS Great Britain (Explorer/Leisure look) deferred to Phase 10.** Reason: the OS Maps API
  needs a key (the app ships none), the Leisure style is served only in British National Grid
  (EPSG:27700) which a Web Mercator MapLibre map cannot display, and premium zooms are paid.
  Future path: self-host OS Open Zoomstack (OGL) as PMTiles. Will not look like paper Explorer.
- **No AllTrails map style.** Reason: proprietary. The `outdoors` style fills that slot and is
  not named or styled after AllTrails.
- **Community heatmap replaced by an OSM GPS traces overlay.** Reason: a real heatmap needs a
  community of uploaded recordings (accounts, a non-goal); Strava's requires login and bars
  third-party use. Public OSM GPS traces are the open substitute (usage policy checked, Cairn
  User-Agent, no bulk download).
- **"Ground conditions" replaced by a "Recent weather" chip.** Reason: AllTrails derives ground
  conditions from user trail reports, which Cairn does not have. The chip shows Open-Meteo
  past-3-day precip/snow/low at the trailhead and is explicitly labeled not a trail report.
- **3D terrain via a bundled MapLibre-GL-JS WebView, not the native map.** Reason: `maplibre_gl`
  (MapLibre Native) throws UnsupportedError on setTerrain; 3D terrain is not shipped on
  Android/iOS yet. Native gets a 2.5D "Tilt" (pitch + hillshade bump, offline); real 3D is an
  online WebView using pinned MapLibre GL JS. Replace with native when it lands.
- **On-device tile proxy for ArcGIS overlays, and loopback cleartext allowed in release.**
  Reason: MapLibre Native does not substitute the `{bbox-epsg-3857}` token in a raster source's
  tile URL, so the radar/temperature/snow/slope/lidar overlays could not fetch tiles. A tiny
  `HttpServer` on `127.0.0.1` (`tile_proxy.dart`) turns `{z}/{x}/{y}` into a Web Mercator bbox,
  fills the token in the upstream URL, and forwards the request. The release network security
  config now permits cleartext to `127.0.0.1`/`localhost` only; loopback never touches the
  network, so transport security for real endpoints is unchanged.
- **Follow-route live navigation is free for everyone (user decided 2026-09-11).** Reason:
  Section 12.4 listed follow mode under Summit, but the user chose to keep Start's live
  heading-up follow, off-route haptic, and recenter free. Phase 9 must not gate it; Summit's
  value comes from other features. Recording tracks were always free.
- **FavoriteTrails and UserWaypoints land in Drift schema v3, not v2.** Reason: Addendum A7
  wrote them as v2, but the sync feature had already claimed schemaVersion 2 (Tombstones +
  Tracks.lastModified). Trust the real code: these two tables ship in a v2 to v3 migration so
  no existing install loses data. Tables are defined inline in `app_database.dart` to match the
  existing convention there, not as separate files under `db/tables/`.

## Fix Pass 1

- **Off-UI compute is a thin `GeoWorker.run` seam over `Isolate.run`, not a long-lived worker.**
  Reason: Fix Pass 1 X1.3.1 requires nothing over 4 ms on the UI isolate and names a "GeoWorker".
  The heavy paths (Overpass decode+parse, GeoJSON build/simplify, routing, snapping, route stats,
  the nearby list) are one-shot and pure, so a shared mutable worker buys nothing over a
  short-lived isolate per call, and a single facade importing every layer would invert the layer
  graph (core importing presentation/domain). Instead `lib/core/worker/geo_worker.dart` exposes a
  generic `GeoWorker.run<R>(label, work)` and each layer keeps its own isolate-backed async
  variant next to the pure function. The one stateful cache we need, decoded DEM tiles, stays on
  the main isolate as an LRU of already-decoded grids.
- **Terrarium DEM tiles decode via `ui.instantiateImageCodec` (engine) plus a worker, not
  `package:image`.** Reason: the pure-Dart PNG decode plus a 65,536 element RGBA to meters loop
  ran on the UI isolate (hypothesis H1, the single heaviest op). The engine codec decodes off the
  UI isolate and the RGBA to meters conversion runs in `Isolate.run`. `package:image` is dropped.
- **Overpass responses are fetched as raw text and decoded in the worker.** Reason: with Dio's
  json response type the `jsonDecode` ran on the UI isolate before the parse. `OverpassSource` now
  returns the response body as a String and `jsonDecode` plus `parseOverpassWays`/`parseOverpassPois`
  run together in one isolate hop.
- **Theme Designer custom themes land in Drift schema v4.** Reason: Fix Pass 1 X4.4 needs
  persistent user themes. `CustomThemes` (nine ARGB color ints plus name/mode) ships in a v3 to v4
  migration. Themes import and export as a `.cairntheme` JSON file and a `cairn-theme-1:` base64
  code; import validates the schema and rejects anything else.

## Phase 6 recording engine (2026-09-11, after the spec audit and the AllTrails benchmark)

- **The foreground service isolate owns the recording; the UI only mirrors it.** Reason: spec
  Phase 6 ("the handler owns the write, the UI just reads") and the audit's top gap (a killed
  app ended the hike). `RecordingTaskHandler` reads a session file, runs the GPS stream through
  the pure `RecordingEngine`, appends every accepted fix and pause transition to a JSONL log
  (flushed per line), and sends snapshots to the main isolate. The handler never touches Drift:
  two isolates on one SQLite file is a locking trap, and a log that replays into the identical
  engine state is simpler and survives every kill. The main isolate ingests the log on Finish,
  on the next launch after Stop was pressed on the notification with the app gone, or as a
  recovered (paused) session when the service itself died.
- **Live gain uses the DEM through `.f32` sidecars, else a 5-point GPS median offset to the
  last DEM reading; never raw GPS deltas.** Reason: spec Phase 6 and the house rule. The
  service isolate has no image codec, so `TerrainTileSource` writes a decoded Float32 sidecar
  next to each cached terrarium PNG and `TerrainSidecarReader` samples it bilinearly. The first
  DEM reading after GPS-only samples re-anchors the hysteresis reference instead of counting the
  ellipsoid-to-terrain offset as a climb or a drop.
- **Auto-pause: 20 s under 0.5 m/s enters, two moving fixes (or 15 m from the pause spot)
  resumes; a 5 s service tick runs it when the distance filter sends no fixes.** Reason: the
  spec's acceptance (within 20 s, resume within 5 s). Active time excludes every pause; the
  distance walked away from an auto-pause spot counts, the wait does not; a manual pause is a
  gap that starts a new segment.
- **Off-route: more than 60 m for 30 s with fixes better than 25 m enters, back within 30 m
  leaves and re-arms; Mute silences until then.** Reason: spec Phase 6 (60 m for 30 s) plus
  AllTrails' mute-until-return behavior; the accuracy gate stops canyon fixes from firing false
  alerts. The alert is two heavy haptic taps, the notification text, and a banner with distance
  and an arrow back to the trail. No separate high-importance notification: the plugin owns one
  channel, kept LOW so a 6 h hike never buzzes for status updates.
- **ETA is Naismith and Langmuir on the remaining profile, scaled by the hiker's own pace.**
  Reason: AllTrails has no computed ETA (the research); the spec asks for "ETA using your own
  moving pace". The scale is observed moving time over Naismith time for what has been covered,
  clamped 0.6 to 2.5 and weighted in over the first 30 minutes of moving.
- **Three GPS power profiles (Precise 5 m / 1 s, Balanced 10 m / 4 s, Saver 30 m / 15 s) plus an
  automatic drop to Saver at 20 percent battery.** Reason: AllTrails offers no low-power mode
  and its users' top safety complaint is battery; the profiles are the spec's location config
  made a setting. Precise stays on the fused provider with best accuracy (the spec's config);
  geolocator falls back to LocationManager where Play services are absent.
- **Battery percent at start and end is stored per track (schema v5) and shown as "%/h".**
  Reason: a measured number beats AllTrails' "10 to 15 percent an hour" guess. `battery_plus`
  (BatteryManager, no Google libraries) is used because Android's sysfs battery node is denied to
  apps by SELinux. Local only, never sent anywhere.
- **The recording sheet collapses to three numbers, the route status, and two buttons.** Reason:
  the mobile track (the map is the hero while navigating); the full grid, ETA, gain left,
  profile with a position dot, and Discard live above the fold. Finish asks once; Pause stays one
  tap. Start zooms to 16 before follow mode takes over, because tracking keeps the current zoom.
- **Keep-screen-on is a two-line method channel in MainActivity, not a plugin.** Reason:
  `FLAG_KEEP_SCREEN_ON` is all that is needed; a dependency for one flag is overhead.

## Offline bundles and the app icon (2026-09-11)

- **Route downloads are corridor bundles: the area around the route at z10 to z14 plus
  z15 to z16 inside a 1.5 km corridor cut into 2.5 km chunks.** Reason: the AllTrails benchmark
  (z14 alone is too coarse to read a junction; a full high-zoom rectangle is too big). MapLibre
  offline regions are rectangles, so the corridor is a chain of small boxes, each tagged with
  the Cairn region id in its metadata; the tile-count limit is raised to 250k once per launch.
  The corridor boxes are not persisted, so Resume on a route bundle refetches only the overview.
- **Delete frees the MapLibre regions by metadata; Resume, Retry and Refresh live on the region
  card.** Reason: spec audit gaps 4 and 6. Refresh forces the trail and POI cells past their
  30-day TTL and refetches land and terrain so a bundle carries current data.
- **Every `offlineAllowed` base map can be downloaded; Outdoors, Terrain and Road count as vector
  in the estimate, Topo and Satellite as raster.** Reason: the picker was still the legacy
  three-style enum.
- **The launcher icon is a drawn cairn (paper stones, gold top, larch ground), generated by
  `tool/make_icons.py`, with an adaptive foreground, monochrome, legacy square, and a white
  status-bar icon for the recording notification.** Reason: the app shipped Flutter's default
  logo; the notification showed it too. Pillow is the only build-time need and the output is
  committed, so CI and F-Droid builds do not run the script.

## Trail detail sheet (2026-09-11, AllTrails benchmark section 5 and 8)

- **A trail is its named ways chained into one line, not a single OSM way.** Reason: the sheet
  opened from a card said "0.7 mi segment" while the card said 4.5 mi. `chainWays` walks from the
  longest way and joins any way whose end lies within 15 m, in either orientation; the longest
  chain feeds the profile, the rating, and Navigate, and a note appears when some ways did not
  connect. Search groups its hits by name the same way.
- **Difficulty is the NPS / Shenandoah score, `sqrt(2 x gain_ft x distance_mi)`: Easy under 50,
  Moderate to 140, Hard to 250, Strenuous above, bumped one band for `sac_scale` T3 and up or
  `trail_visibility` bad / horrible / no.** Reason: AllTrails' equation is unpublished; this one
  reproduced its label on all seven benchmark trails (docs, research 2026-09-11). The score and
  its inputs sit in the chip's tooltip so the label is explainable. T2 does not bump: it is an
  ordinary mountain trail in OSM's scale.
- **Two times: "Typical" (5.35 km/h plus one hour per 248 m of gain, floored to a half-hour
  band) and "Fit" (Naismith and Langmuir).** Reason: the Typical pace is the fit to AllTrails'
  published bands and absorbs rests; hikers know that number. Naismith stays as the honest
  moving-time estimate and the ETA basis.
- **Lengths on the sheet are one way, with the route type (one way, loop, out and back) as a
  chip.** Reason: OSM trails are lines, not curated hikes; an out-and-back on a 4.5 mi trail is
  the hiker's choice, and doubling silently would misstate the data.
- **Sights along the way come from the cached OSM POIs within 100 m of the line (peaks, saddles,
  viewpoints, springs, water, campsites, huts, shelters) and parking or a trailhead within 300 m
  of the start; matched in a worker.** Reason: AllTrails' "Top sights" and "Plan your visit"
  without any community data, and it works offline inside a downloaded region.

## Navigation rendering (2026-09-11, AllTrails benchmark section 1)

- **The traveled path is its own teal `track` layer above the gold route, fed from the
  recording snapshots and refetched from the service on re-attach.** Reason: AllTrails draws
  the planned route and the walked path in two colors; with one color you cannot tell a wrong
  turn from the plan. Points ride along with each snapshot (one per accepted fix) so nothing
  extra crosses the isolate boundary in the common case.
- **Direction chevrons on the active route from z14 (`route-arrows`, a symbol layer with an
  icon registered at runtime).** Reason: an out-and-back or a loop reads the same in both
  directions without them; the icon is drawn in Dart like the POI dots so no sprite sheet is
  needed and it follows the theme.
- **The debug location simulator toggle is persisted.** Reason: it is debug-only, and a
  reinstall-and-test loop reset it on every build.
- **Climbs are runs where the grade smoothed over 100 m stays at or above 6 percent (a dip
  under 60 m does not end one) gaining at least 30 m; the recording sheet shows distance and
  gain left to the top of the climb under way.** Reason: AllTrails' Android climb pill and
  its 6 percent shading threshold (benchmark sections 2 and 6). Computed once from the
  route's DEM profile when a recording starts, so it works offline and costs nothing per fix.
- **The privacy screen renders a markdown-lite asset (title, headings, bullets) generated
  from docs/PRIVACY.md, and the sources screen lists every feed and the map engine.** Reason:
  the plain-text version had no structure and had fallen behind the policy; the sources list
  lacked USFS, the NWS weather maps, USGS 3DEP, OSM GPS traces, IGN and MapLibre.

## Divergences recorded after the spec audit (2026-09-12)

- **Overpass budgets are 35 s query / 40 s receive, not the spec's 60 / 90.** Reason: Fix Pass 1
  H4. With three mirrors, failing over fast beats waiting on a slow one; a 90 s hang read as a
  frozen app. A z10 cell that cannot finish in 35 s on any mirror is the exception, and the cached
  data plus the offline banner cover it.
- **Open-Meteo is requested in SI (celsius, m/s), not the spec's literal fahrenheit/mph URL.**
  Reason: Section 2 stores everything internally in SI and formats at the edge with
  UnitFormatter; asking the API for imperial would mean converting back.
- **`WAKE_LOCK` is the eighth permission.** Reason: `flutter_foreground_task` with `allowWakeLock`
  keeps the CPU awake for location fixes while the screen is off during a recording. Plugin
  permission review: geolocator (location), flutter_foreground_task (foreground service, wake
  lock, notifications), permission_handler (runtime prompts only), share_plus / url_launcher /
  file_picker / webview_flutter (no permissions beyond intents).
- **`gainLoss` uses a 5 m deadband, not the spec's snippet.** Reason: the snippet double-counted
  across the threshold; the deadband implements the intent (5 m hysteresis) and is unit-tested.
- **Dashed trail and route variants are separate style layers with a constant dash.** Reason:
  MapLibre Native rejects a data-driven `line-dasharray` (`[ParseStyle]: data expressions not
  supported`) and drops the whole layer, so the `trails` and `route` layers never rendered on
  Android; only the list and the casing showed. `trails-informal` and `route-offtrail` now carry
  the dash behind a property filter (`tool/patch_cairn_layers.dart`, idempotent, run after
  regenerating a style).
- **The 3D view drapes the active base map on the terrain, built in Dart.** Reason: Fix Pass 1 X3
  found the 3D view showed bare grey hillshade with no base map, route, or labels. The WebView now
  loads the active base map's own style JSON (its sources already use absolute HTTPS URLs and carry
  a terrain-dem source plus cairn-route/route layers), injects the route, enables setTerrain, and
  frames the route then tilts. A single MapLibre error no longer blanks the view: only a total
  failure to reach load within 12 s shows the offline message, now with Retry. NOTE: on-device 3D
  rendering could not be verified on the CI emulator because its WebView has no working WebGL
  (MESA rendernode failure); it renders on a real device (the original grey-terrain report proves
  the phone's WebView WebGL works). Verify on the physical phone.
