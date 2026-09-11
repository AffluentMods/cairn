<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# CAIRN Fix Pass 1: Stability, Navigation Reliability, 3D, Themes

**Date:** 2026-09-11
**Applies to:** current build after Phase R and partial Addendum B work

Fix Pass 1 blocks all feature work. Finish it before any other phase.

---

## X0. What happened and how to work this pass

User testing on the emulator and a physical phone found:

1. **ANR** ("Cairn isn't responding") after tapping locate on Explore. Later the whole device became unresponsive.
2. **Show route** moved to the map and nothing visible happened; app felt frozen or crashed.
3. **Navigate this trail** is unusable: the camera does not frame the route, the route line is not visible or renders as a dark smear, and there is no sense of where to go.
4. **Explore map renders black** at first, while the Trails in view list is already filled.
5. **3D view** shows grey terrain only: no basemap, no route, no labels, camera far off.
6. **Navigate sheet:** title says "Navigate" instead of the route name; Download and Start are clipped at the bottom; the profile fill is a noise of vertical red and green stripes; min and max labels sit on top of the line.
7. **Trails in view** lists forest roads ("Forest Road 7068").
8. **Look and feel is flat.** The user wants a theme system like ZestSSH: built-in themes plus a Theme Designer for custom themes.

Rules for this pass:

- Measure before fixing. Capture evidence first (X1.1) into PROGRESS under "Fix Pass 1 evidence". Fix at the root. Re-measure with the same method.
- Physical Android phone is the source of truth for maps, location, and performance. The emulator is for reproduction and simulated location.
- Commit per section: `fix-1.<section>: <what>`. Final commit `fix-1: stability, navigation, 3d, themes`.
- House rules still apply: l10n for every string, no em dashes, SPDX headers, analyzer clean.

## X1. Stability and performance

### X1.1 Capture evidence first
Reproduce each path (locate on Explore, pan Rainier z11-13, Show route, Navigate this trail, 3D, two overlays + zoom 16). Record DevTools timeline/CPU, ANR main-thread stack from `adb bugreport`, `dumpsys meminfo` before/after, `adb logcat -s flutter,MapLibre,chromium,AndroidRuntime`, network requests per minute.

### X1.2 Hypotheses (confirm or rule out with evidence)
- H1 Terrarium PNG decode (package `image`, pure Dart) on the UI isolate per tile.
- H2 Every camera idle recomputes Trails in view (50 items incl DEM gain) and resends full trails GeoJSON.
- H3 Overpass parse, way/relation assembly, Douglas-Peucker, Dijkstra on the UI isolate.
- H4 Locate animates to a dense area, firing multiple camera idles and overlapping uncancelled fetches.
- H5 `getCurrentPosition` has no time limit and hangs.
- H6 Overlays have no `maxzoom`, so at z16+ hundreds of dynamic ArcGIS renders are requested.
- H7 Overlays added on top, hiding the route and trails.
- H8 3D WebView not disposed on close; GL context and tile cache stay alive.
- H9 Explore and Navigate both keep a MapLibre view alive.
- H10 `setGeoJsonSource` called with multi-MB JSON over the platform channel every update.

### X1.3 Required fixes
- X1.3.1 Nothing over 4 ms on the UI isolate: `GeoWorker` isolate for Overpass parse/ingest prep, relation assembly, GeoJSON build/simplify, snapping, Dijkstra, resample, DEM lookups, gain/loss, profile downsample, Trails-in-view build. Terrarium decode via `ui.instantiateImageCodec` (engine), not package `image`, then RGBA->Float32 meters in the worker (LRU 64 tiles).
- X1.3.2 One viewport pipeline with 400 ms debounce, generation counter, and cancellation. Every async result checks `isCurrent(gen)`.
- X1.3.3 Trails in view: build in worker (length only), gain lazy per visible card (max 4 in flight, cached), cap 30, exclude `highway=track` (a `trailsIncludeRoads` chip, off by default, adds them back).
- X1.3.4 GeoJSON updates hashed (FNV-1a) and skipped if unchanged; cap 2,000 features; below z11 render only named ways and relation members.
- X1.3.5 Location never blocks: last-known first, `getCurrentPosition` with an 8 s timeLimit, `LocationResult` of fix/stale/noFix/servicesOff/permission. Locate moves to last-known immediately, refines on fresh fix (>50 m), never triggers a data fetch.
- X1.3.6 Overlays bounded: per-source `maxzoom` (radar 10, temp 8, snow 10, slope 14, lidar 15, gps 16), added below the first Cairn layer, max two network overlays, paused while the follow camera animates.
- X1.3.7 Layer order contract with a debug assertion after style load.
- X1.3.8 Local crash and stall log (no third-party SDK); Settings > Diagnostics to view/share/clear; no coordinates in logs; UI stall watchdog in debug.
- X1.3.9 3D WebView disposed on close (about:blank, clear channel, dispose); Graphics returns within 20 MB.
- X1.3.10 Map loading state (theme bg + spinner + `mapLoading`) until `onStyleLoadedCallback`; 10 s timeout shows `mapLoadFailed` with Retry. No black screen.

### X1.4 Budgets (physical phone, profile): cold start < 2.5 s; locate->puck < 300 ms with last-known; pan z12 no frame > 32 ms after first second; Show route camera < 300 ms, highlight < 1 s; memory < 350 MB PSS; zero ANRs in a 10 min session.

## X2. Navigation reliability
Benchmark AllTrails: tap a trail, the map frames it (start/end/direction/position), tap Start and it follows.

- X2.1 `active_route_controller.dart` owns loading: build geometry in worker, set `cairn-route` + `cairn-route-endpoints`, snap the sheet to 0.45 and read its pixel height, fit the camera to route bounds with padding clearing every overlay (left/right button columns, status bar, sheet height + 24), then compute profile/conditions async. Every entry point uses it.
- X2.2 Which section: whole trail if a named relation/way chain < 15 mi (start nearest a trailhead within 500 m, else nearest the user, else first vertex); else the viewport section + 25% snapped to graph vertices. Show `navRouteFromTo`; if start > 1 mi away show `navStartFar` with Directions.
- X2.3 Route rendering: casing + line (zoom-interpolated width, theme route color via a `color` property), `route-arrows` symbols (route-arrow sprite) at z12+, `route-endpoints` circles (start green, end red). Loops draw one start marker. Off-trail on `cairn-route-offtrail`.
- X2.4 Sheet: title is the route/hike name (`routeUnnamed` fallback), a `navRouteFromTo` line, a `CustomScrollView` in `SafeArea(top:false)` with the action row fully visible at 0.45 on 360x640 and 412x915 (widget tests). Stat values never wrap; drop the clock icon first below 360 dp.
- X2.5 Profile redraw: downsample to one point per pixel (worker), grade over a 100 m window merged into runs, one neutral fill + one accent progress fill (no per-sample fills), grade-colored line runs, right-gutter labels not overlapping, scrubber + map marker. Paint < 4 ms for 5,000 points.
- X2.6 Active navigation after Start: follow with heading-up, sheet to a 0.14 navigation strip (distance/elev remaining/ETA/on-route), top HUD next landmark, Recenter pill after a pan, traveled section dimmed, off-route amber + rejoin line + one haptic, wakelock while visible.
- X2.7 Show route: stay on Explore, collapse the trail sheet, assemble relation in the worker (cache by id), draw on `cairn-highlight` and fit the camera, show a Clear pill, a progress indicator if > 300 ms, never freeze.
- X2.8 Simulated walking (debug/profile): `simulateAlong` stream + `LocationSource` interface (device/simulated); Settings > Developer sim controls; document emulator GPX playback in BUILDING.md.

## X3. 3D view repair
- X3.1 WebView console logging in debug; build the 3D style in Dart from the active base map (absolute sprite/glyph URLs, keep raster bases, drop overlays and non-route cairn sources); `setTerrain` exaggeration 1.2 + sky/fog from theme; route casing/line + start/end markers; `fitBounds` then `easeTo` pitch 62; Close + bearing reset + Fly-along-route; offline/failure shows `nav3dNeedsConnection` with Retry.

## X4. Visual refresh and theme system
- X4.1 Every presentation color from theme tokens (`context.cairn`); `AppColors` keeps only semantic map colors (fire, smoke/caution, closure/stale, grade greens/amber/red, water, start green, end red). Accent is a token; switches use accent on-state; `onAccent` computed by contrast.
- X4.2 `CairnThemeData` tokens + `CairnColors` ThemeExtension + `context.cairn`. `app_theme.dart` maps a ColorScheme explicitly (not fromSeed).
- X4.3 Seven built-ins (Larch default dark, Paper default light; Basalt, Glacier, Alpenglow, Headlamp, Topo) with a contrast unit test. Appearance settings: Mode (System/Dark/Light) + Dark theme + Light theme pickers.
- X4.4 Theme Designer mirroring ZestSSH: Themes grid with live preview cards; Designer with a pinned live Navigate preview, start-from, mode, color rows (Accent/Background/Surface/Raised/Outline/Text/Secondary/Route/Track) with curated swatches + a custom HSV+hue+HEX+RGB picker, map-button style, name, Save. Drift `CustomThemes` table (migration test); export as `.cairntheme` file + `cairn-theme-1:` code; import validates schema.
- X4.5 Visual refresh: nav bar on `background` with a top border + filled active icon + indicator pill; 48 dp map buttons, Layers+Conditions grouped into one pill, locate is a plain round button; sheets 24 dp corners; buttons (filled accent / outlined textPrimary); mono tabular numbers; 220 ms sheet snaps, 600 ms camera fits, respect reduce-motion.
- X4.6 Migration: replace non-semantic `AppColors` with tokens; `tool/check_theme_tokens.sh` fails CI on `AppColors` (outside allowlist) or `Color(0x` in presentation; theme-dependent style colors set at runtime.

## X6. Order of work
1. X1.1 evidence. 2. X1.3.8 crash log + X1.3.10 loading state. 3. X1.3.1 worker, X1.3.2 pipeline, X1.3.3 list, X1.3.4 GeoJSON, X1.3.5 location. 4. X1.3.6/7 overlays + layer order. 5. X2.8 simulator then X2.1-X2.7. 6. X1.3.9 + X3. 7. X4. 8. Re-run the X1.5 scripted session.
