# CAIRN: Build Spec for Claude Code

**Working name:** Cairn (a trail marker built from stacked rocks). Package `cairn`, bundle id `com.affluentlabs.cairn`. Rename later is a find-and-replace; do not block on it.

**One-line pitch:** An offline-first trail map and route planner for Washington hikers that shows what AllTrails will not: active fire perimeters, smoke, closures, water sources, and permit boundaries, on top of USGS topo and OpenStreetMap trails. No account. No subscription.

**Publisher:** Affluent Labs. Same house rules as ZestSSH and Recipe Spellbook.

**License and model:** Open source under GPL-3.0-or-later (app) and AGPL-3.0-or-later (proxy). Public GitHub repo from day one. Two builds from one codebase: the **community build** (GitHub Releases, F-Droid) with every feature unlocked, and the **store build** (Google Play, later App Store) with a one-time USD 9.99 "Cairn Summit" unlock for convenience features. Same source, one flag. Details in Section 12.

**Target:** Android first (Flutter). iOS second. No desktop.

---

## 0. How Claude Code should use this document

This spec is written so you can work for days without asking questions. Rules:

1. Work through the phases in order. Do not start Phase N+1 until Phase N's acceptance checklist passes.
2. Every decision that could stop you is pre-answered in Section 13 (Q&A). Read it before starting. If something is not answered there, pick the option that ships fastest, write the choice into `docs/DECISIONS.md`, and keep going.
3. Keep a running log in `docs/PROGRESS.md`: what is done, what is next, what failed and why. Update it at the end of every phase and whenever you hit a blocker.
4. When an external API returns something different from what this doc says, trust the live API. Write the real field names into `docs/API_NOTES.md` and adapt the code. APIs drift; this doc was researched on 2026-09-10.
5. Verify before writing: `flutter pub add <pkg>` resolves the current version. Use that. The versions in this doc are known-good floors, not pins.
6. Never hardcode a user-visible string. Every string goes in `lib/l10n/app_en.arb` with a key. This is a hard rule across all Affluent Labs apps.
7. No em dashes anywhere: not in code comments, not in `.arb` files, not in docs, not in commit messages. Use commas, periods, colons, or parentheses.
8. Commit at the end of every phase with the message format `phase-N: <what shipped>`. Small commits inside a phase are fine.
9. Run `flutter analyze` and `flutter test` before every commit. Zero analyzer warnings is the bar.
10. Do not add analytics, crash reporting SDKs, ads, or any third-party tracking. Location data never leaves the device except for the specific API calls listed in Section 5, which only send a coordinate or bounding box.

---

## 1. Product brief

### Who this is for

One user to start: a Tacoma-based hiker doing 15 to 20 mile day pushes with a 40 to 50 lb pack, solo backpacking in the Cascades, planning trips off USGS topo, checking InciWeb and Gifford Pinchot alerts by hand before every trip in a bad fire year. Then everyone like them.

### What AllTrails does that we need

- Browse trails on a map, tap one, see distance, elevation gain, elevation profile
- Draw a custom route, get distance and gain
- Download the map for offline use
- Record a hike (distance, moving time, pace, gain)
- Import and export GPX

### What AllTrails does that we do not need

- User accounts, social feed, reviews, photos from strangers, gamification, paid tiers that gate maps

### What we do that AllTrails does not

- **Conditions overlay:** active fire perimeters and incident points (NIFC, updated every 5 min), air quality now and forecast, NWS weather for the trailhead and the high point of the route, red flag warnings, sunrise/sunset/moon phase for the trip dates
- **Land layers:** wilderness boundaries (self-issue permit reminders), national forest and national park boundaries (which pass you need), trailhead parking with pass requirements
- **Trip water:** springs, streams, and lakes from OSM along the route with distance markers, plus a "last water before the climb" callout
- **Pack-aware stats:** calorie and effort estimates that account for pack weight
- **Truly offline:** map tiles, elevation data, and trail geometry all cached locally; the app works with airplane mode on

### Non-goals for v1

- Turn-by-turn voice navigation
- Community features
- Web version
- Anything that requires a Cairn account

---

## 2. Standing rules (Affluent Labs conventions)

These apply to every file in the repo.

- **Flutter + Dart.** Same toolchain as ZestSSH and Recipe Spellbook.
- **Localization:** `flutter_localizations` + `intl` with `lib/l10n/app_en.arb`. Access strings via `context.l10n.keyName` (see Section 10 for the extension). Add every new key to the `.arb` in the same commit that uses it.
- **No em dashes** in any output. `.arb` values included.
- **Release builds:** `flutter build appbundle --release --obfuscate --split-debug-info=debug-symbols/<version>`. Keep the symbols folder; it is gitignored.
- **No account required, ever.** Purchases (if any) go through RevenueCat with Google sign-in for restore only. See Section 12.
- **Secrets never ship in the binary.** Anything that needs an API key (AirNow, NPS, RIDB) goes through a tiny proxy on the Affluent Labs server. Everything else in Section 5 needs no key.
- **Units:** default imperial (miles, feet, °F) because the first users are in the US. Metric toggle in settings. Store everything internally in meters and Celsius. Format only at the edge.
- **Dark and light themes, follow system by default.**
- **Strings:** plain, direct, human. No "Oops!", no "Awesome!", no exclamation points in error messages. Read the copy rules in Section 9.5.

---

## 3. Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter app (Android, iOS later)                            │
│                                                              │
│  presentation/   Riverpod providers + widgets per feature    │
│  domain/         pure Dart models + use cases (no Flutter)   │
│  data/           repositories, Drift DB, HTTP clients        │
│  core/           theme, l10n, routing, utils, geo math       │
│                                                              │
│  Map engine: maplibre_gl (native MapLibre, GPU, offline)     │
│  Storage:    Drift (SQLite) + file cache for tiles/DEM       │
│  Location:   geolocator + flutter_foreground_task            │
└───────────┬──────────────────────────────────────────────────┘
            │ HTTPS only, no keys
            ▼
  OpenFreeMap tiles   AWS Terrain Tiles (DEM)   USGS Topo/Imagery
  Overpass (OSM)      NIFC WFIGS (fires)        api.weather.gov
  USFS EDW (trails, wilderness, forests)        Open-Meteo (AQI, fallback wx)
            │
            ▼ (Phase 8, optional, keys live here, not in app)
  Affluent Labs proxy: /aqi (AirNow), /nps/alerts, /ridb, /restrictions.json
```

### Layering rules

- `domain/` has no imports from Flutter, Drift, or Dio. Pure Dart. Fully unit-testable.
- `data/` implements repository interfaces declared in `domain/`.
- `presentation/` only talks to providers. Widgets never call repositories directly.
- Geometry math lives in `core/geo/` and is unit tested against known values (see Section 14).

### State management

Riverpod (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`). Code generation via `build_runner`. One `ProviderScope` at root.

### Navigation

`go_router`. Bottom nav with 4 tabs: Map, Plan, Record, Library. Settings is reachable from the Library tab's app bar, not a fifth tab.

---

## 4. Tech stack and dependencies

Run `flutter pub add` for each. Floors listed; use whatever resolves.

### pubspec.yaml (dependencies)

```yaml
name: cairn
description: Offline trail maps with fire, smoke, and closure overlays.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.6.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.0

  # State + routing
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0
  go_router: ^14.0.0

  # Map engine (native MapLibre, BSD-3, offline regions, PMTiles, hillshade)
  maplibre_gl: ^0.22.0

  # Storage
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  shared_preferences: ^2.3.0        # non-sensitive settings only
  flutter_secure_storage: ^9.2.0    # only if a secret ever needs to exist on device

  # Network
  dio: ^5.7.0

  # Geo
  latlong2: ^0.9.1
  turf: ^0.0.10                     # nearestPointOnLine, along, length, bbox
  gpx: ^2.3.0                       # GPX read/write
  image: ^4.3.0                     # decode terrarium PNG tiles for elevation

  # Location + recording
  geolocator: ^13.0.0
  flutter_foreground_task: ^8.17.0
  permission_handler: ^11.3.0

  # Misc
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  share_plus: ^10.0.0
  file_picker: ^8.1.0
  url_launcher: ^6.3.0
  collection: ^1.19.0
  uuid: ^4.5.0

  # Monetization (Phase 9 only, gated)
  purchases_flutter: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  drift_dev: ^2.22.0
  freezed: ^2.5.0
  json_serializable: ^6.9.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/map_styles/
    - assets/data/
```

### Why maplibre_gl and not flutter_map

- Native GPU rendering, vector tiles, hillshade and color-relief layers from a raster DEM source, and **built-in offline region downloads** (`downloadOfflineRegion`). BSD-3 licensed.
- flutter_map is excellent and, since Cairn is GPL itself, its GPL-3 bulk-download plugin (`flutter_map_tile_caching`) would be allowed. It still loses on hillshade quality, vector rendering, and battery: MapLibre renders on the GPU natively and has offline regions built in. If the project ever needs desktop or web, flutter_map is the fallback engine; note that decision in `docs/DECISIONS.md` if it happens.
- Trade-off: the map is a platform view, so Flutter widgets go **over** it in a `Stack`, not between its layers. Every overlay (route lines, markers, fire polygons) is a MapLibre layer fed by a GeoJSON source, not a Flutter widget. Design for that from Phase 1.
- No desktop support. Fine, this app is mobile only.

### l10n config: `l10n.yaml` at repo root

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
    avoid_print: true
    require_trailing_commas: true
```

---

## 5. Data sources and APIs

Everything here is free and needs no key unless marked. Attribution requirements are listed; render them in the map's attribution control and in Settings > About.

### 5.1 Base map tiles

| Layer | Source | URL | Notes |
|---|---|---|---|
| Outdoors (vector, default) | OpenFreeMap | `https://tiles.openfreemap.org/styles/liberty` | Free, no key, no stated limits, OSM data (ODbL). Attribution: "© OpenFreeMap © OpenMapTiles Data from OpenStreetMap". If usage grows, self-host Protomaps PMTiles (Section 5.9). |
| USGS Topo (raster) | USGS The National Map | `https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}` | Public domain. Has contour lines baked in. Note the `{z}/{y}/{x}` order (ArcGIS). Max useful zoom 16. |
| Satellite (raster) | USGS Imagery | `https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/MapServer/tile/{z}/{y}/{x}` | Public domain. |
| Hillshade + elevation (raster-dem) | AWS Terrain Tiles (Mapzen/Tilezen Terrarium) | `https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png` | Free, no key, AWS Open Data. `encoding: terrarium`, `tileSize: 256`, **`maxzoom: 15`** (set this or MapLibre requests tiles that do not exist). Attribution: "Terrain: Mapzen/AWS Terrain Tiles". |

Terrarium decode (used both by MapLibre internally and by our own elevation code):

```
elevation_m = (R * 256 + G + B / 256) - 32768
```

### 5.2 Trails and paths: OpenStreetMap via Overpass

Endpoint: `https://overpass-api.de/api/interpreter` (POST, body is the query). Mirrors if rate limited: `https://overpass.kumi.systems/api/interpreter`, `https://overpass.private.coffee/api/interpreter`. Send a `User-Agent: Cairn/<version> (contact@affluentlabs.dev)` header. Be polite: one request at a time, cache aggressively (Section 7), never query more than a z10 tile's bbox at once.

Query (bbox is `south,west,north,east`):

```
[out:json][timeout:60];
(
  way["highway"~"^(path|footway|track|bridleway|steps)$"]({{bbox}});
  relation["route"~"^(hiking|foot)$"]({{bbox}});
);
out body;
>;
out skel qt;
```

Tags to keep per way: `name`, `highway`, `sac_scale`, `trail_visibility`, `surface`, `informal`, `access`, `operator`, `ref`. Route relations give named trails (`name`, `network`, `distance`, `osmc:symbol`) and their member way ids.

Points of interest (separate query, same bbox):

```
[out:json][timeout:60];
(
  node["natural"~"^(spring|water|peak|saddle)$"]({{bbox}});
  node["tourism"~"^(camp_site|wilderness_hut|viewpoint)$"]({{bbox}});
  node["amenity"~"^(toilets|drinking_water|parking|shelter)$"]({{bbox}});
  node["highway"="trailhead"]({{bbox}});
  way["natural"="water"]({{bbox}});
  way["waterway"~"^(stream|river)$"]({{bbox}});
);
out body;
>;
out skel qt;
```

License: ODbL. Attribution "© OpenStreetMap contributors" is mandatory wherever OSM-derived data is shown.

### 5.3 USFS official trails, wilderness, and forest boundaries (ArcGIS REST)

All public, no key, `f=geojson` supported. Query pattern:

```
{base}/query?where=1%3D1&geometry={xmin},{ymin},{xmax},{ymax}&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&outSR=4326&f=geojson
```

| Dataset | Base URL | Use |
|---|---|---|
| National Forest System Trails | `https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_TrailNFSPublish_01/MapServer/0` | Official trail names and numbers (e.g. "Snowgrass Trail #96"). Enrich OSM ways by proximity match. |
| Wilderness areas | `https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_Wilderness_01/MapServer/0` | Polygon overlay. Entering one triggers the "self-issue wilderness permit required" callout for Gifford Pinchot forests. |
| Forest boundaries | `https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_ForestSystemBoundaries_01/MapServer/0` | Which forest a point is in. Drives the "check alerts for X National Forest" deep link. |
| MVUM roads | `https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_MVUM_01/MapServer` | Optional, for "is this forest road open to passenger vehicles" (v2). |

Field names vary per layer. On first run, hit `{base}?f=json` and write the field list into `docs/API_NOTES.md`.

### 5.4 Wildfire: NIFC WFIGS (updated every 5 minutes, CC-BY 3.0)

| Dataset | URL |
|---|---|
| Current fire perimeters (polygons) | `https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Interagency_Perimeters_Current/FeatureServer/0` |
| Current incident locations (points, includes fires with no perimeter yet) | `https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Incident_Locations_Current/FeatureServer/0` |

Same ArcGIS `query` pattern as 5.3 with `f=geojson` and a bbox. Useful fields (verify live): `poly_IncidentName`, `poly_GISAcres`, `attr_PercentContained`, `attr_FireDiscoveryDateTime`, `attr_IncidentTypeCategory` (WF = wildfire, RX = prescribed), `attr_FireBehaviorGeneral`, `attr_ModifiedOnDateTime_dt`. Points layer uses `attr_` fields without the `poly_` prefix.

Attribution: "Fire data: NIFC WFIGS". Show the `ModifiedOnDateTime` as "updated X min ago" on every fire card so nobody trusts stale data.

InciWeb has no clean public JSON API. Link out: `https://inciweb.wildfire.gov/` search by incident name.

### 5.5 Weather: NWS (api.weather.gov), free, no key

Requires a `User-Agent` header identifying the app: `Cairn/<version> (contact@affluentlabs.dev)`. Requests without it get rejected.

1. `GET https://api.weather.gov/points/{lat},{lon}` returns `properties.forecast`, `properties.forecastHourly`, `properties.forecastGridData`.
2. Follow `forecastHourly` for the 7-day hourly.
3. Alerts: `GET https://api.weather.gov/alerts/active?point={lat},{lon}` (red flag warnings, winter storm, excessive heat).

Fetch for two points per route: the trailhead and the highest point of the route. Mountain weather is not valley weather.

Fallback and elevation-aware temps: Open-Meteo, free, no key:
`https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&hourly=temperature_2m,precipitation_probability,wind_speed_10m,wind_gusts_10m,cloud_cover&temperature_unit=fahrenheit&wind_speed_unit=mph&forecast_days=7&elevation={m}`

### 5.6 Air quality

**MVP (no key):** Open-Meteo Air Quality:
`https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&hourly=us_aqi,pm2_5&forecast_days=3`
Model-based (CAMS), decent for smoke plumes, not monitor-accurate.

**Phase 8 (key via proxy):** EPA AirNow, monitor-based. Endpoint `/aq/observation/current/ziplatlong/` (the older lat/long endpoint is retired 2026-09-30, do not use it). 500 requests/hour per key per service. Observations update hourly, so cache for 30 minutes. Key lives on the proxy, never in the app.

### 5.7 Elevation

Primary: decode terrarium tiles at z14 locally (Section 8.3). Works offline once tiles are cached. Resolution at z14 in Washington is roughly 9 m per pixel, which is fine for profiles and gain.

Spot-check fallback (online): `https://api.open-meteo.com/v1/elevation?latitude={lat1},{lat2}&longitude={lon1},{lon2}` (up to 100 coordinates per request, no key).

### 5.8 Land management, permits, campgrounds (Phase 8, keys via proxy)

| Source | Notes |
|---|---|
| NPS API `https://developer.nps.gov/api/v1/alerts?parkCode=mora,olym,noca` | Free key. Park alerts (closures, fire). Rainier `mora`, Olympic `olym`, North Cascades `noca`. |
| Recreation.gov RIDB `https://ridb.recreation.gov/api/v1/facilities?latitude=&longitude=&radius=` | Free key. Campgrounds, trailheads, permit facilities. |
| Affluent Labs `restrictions.json` | Hand-maintained JSON of current fire restriction stages and burn bans per forest. No public API exists for these. Schema in Section 8.7. |

### 5.9 Self-hosted PMTiles (optional, Phase 10)

If OpenFreeMap usage becomes a concern or you want guaranteed offline vector basemaps: build a Washington + Oregon extract with Planetiler or Protomaps `pmtiles extract`, host the `.pmtiles` file on the Affluent Labs box behind nginx with HTTP range requests enabled, point the style at `pmtiles://https://tiles.affluentlabs.dev/pnw.pmtiles`. MapLibre handles the `pmtiles://` protocol natively on Android and iOS. Same for a WA trails vector tileset built from OSM with tippecanoe, which would replace live Overpass calls entirely.

---

## 6. Repository layout

Create exactly this. Empty files with a header comment are fine as placeholders in Phase 0.

```
cairn/
├── CLAUDE.md                          # house rules for Claude Code (Section 15)
├── README.md
├── l10n.yaml
├── analysis_options.yaml
├── pubspec.yaml
├── docs/
│   ├── PROGRESS.md                    # running log, update every phase
│   ├── DECISIONS.md                   # every choice made without the user
│   ├── API_NOTES.md                   # real field names discovered at runtime
│   └── PRIVACY.md                     # draft privacy policy text
├── assets/
│   ├── map_styles/
│   │   ├── outdoors.json              # OpenFreeMap liberty + terrain + our layers
│   │   ├── topo.json                  # USGS Topo raster + our layers
│   │   └── satellite.json             # USGS Imagery + hillshade + our layers
│   └── data/
│       └── wa_parks.json              # park codes and forest names for WA (seed)
├── lib/
│   ├── main.dart
│   ├── app.dart                       # MaterialApp.router, theme, l10n delegates
│   ├── l10n/
│   │   └── app_en.arb
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_typography.dart
│   │   ├── l10n/
│   │   │   └── l10n_ext.dart          # BuildContext.l10n
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── geo/
│   │   │   ├── haversine.dart
│   │   │   ├── polyline_simplify.dart # Douglas-Peucker
│   │   │   ├── tile_math.dart         # lat/lon <-> tile x/y/z, pixel in tile
│   │   │   ├── terrarium.dart         # RGB -> meters
│   │   │   ├── elevation_stats.dart   # gain/loss with hysteresis
│   │   │   ├── solar.dart             # sunrise/sunset/civil twilight
│   │   │   └── moon.dart              # phase + illumination
│   │   ├── units/
│   │   │   └── unit_formatter.dart    # meters -> "12.4 mi", etc.
│   │   └── net/
│   │       ├── dio_client.dart        # base Dio with User-Agent, timeouts
│   │       └── arcgis_query.dart      # builds ArcGIS REST query URLs
│   ├── domain/
│   │   ├── models/
│   │   │   ├── trail.dart             # freezed
│   │   │   ├── route_plan.dart
│   │   │   ├── track.dart
│   │   │   ├── track_point.dart
│   │   │   ├── poi.dart
│   │   │   ├── fire_incident.dart
│   │   │   ├── weather_forecast.dart
│   │   │   ├── air_quality.dart
│   │   │   ├── offline_region.dart
│   │   │   └── land_unit.dart         # forest / wilderness / park polygon
│   │   ├── repositories/              # abstract classes only
│   │   │   ├── trail_repository.dart
│   │   │   ├── poi_repository.dart
│   │   │   ├── elevation_repository.dart
│   │   │   ├── conditions_repository.dart
│   │   │   ├── track_repository.dart
│   │   │   ├── route_repository.dart
│   │   │   └── offline_repository.dart
│   │   └── usecases/
│   │       ├── compute_route_stats.dart
│   │       ├── snap_to_trail.dart
│   │       ├── route_between_waypoints.dart   # graph search over OSM ways
│   │       ├── water_along_route.dart
│   │       └── trip_calories.dart
│   ├── data/
│   │   ├── db/
│   │   │   ├── app_database.dart      # Drift
│   │   │   └── tables/
│   │   │       ├── osm_ways.dart
│   │   │       ├── osm_nodes.dart
│   │   │       ├── osm_relations.dart
│   │   │       ├── pois.dart
│   │   │       ├── tracks.dart
│   │   │       ├── track_points.dart
│   │   │       ├── routes.dart
│   │   │       ├── route_waypoints.dart
│   │   │       ├── offline_regions.dart
│   │   │       ├── cache_cells.dart   # which z10 cells are cached + when
│   │   │       └── conditions_cache.dart
│   │   ├── sources/
│   │   │   ├── overpass_source.dart
│   │   │   ├── usfs_source.dart
│   │   │   ├── nifc_source.dart
│   │   │   ├── nws_source.dart
│   │   │   ├── open_meteo_source.dart
│   │   │   ├── terrain_tile_source.dart   # fetch + disk cache terrarium PNGs
│   │   │   └── affluent_proxy_source.dart # Phase 8
│   │   └── repositories/              # concrete impls
│   │       └── ... one per interface
│   ├── presentation/
│   │   ├── shell/
│   │   │   └── app_shell.dart         # bottom nav
│   │   ├── map/
│   │   │   ├── map_screen.dart
│   │   │   ├── map_controller_provider.dart
│   │   │   ├── layers/                # each adds/removes MapLibre sources+layers
│   │   │   │   ├── trails_layer.dart
│   │   │   │   ├── pois_layer.dart
│   │   │   │   ├── fires_layer.dart
│   │   │   │   ├── land_layer.dart
│   │   │   │   ├── route_layer.dart
│   │   │   │   └── track_layer.dart
│   │   │   └── widgets/
│   │   │       ├── layer_switcher_sheet.dart
│   │   │       ├── trail_detail_sheet.dart
│   │   │       ├── conditions_panel.dart
│   │   │       └── location_fab.dart
│   │   ├── plan/
│   │   │   ├── plan_screen.dart
│   │   │   ├── route_editor_provider.dart
│   │   │   └── widgets/
│   │   │       ├── elevation_profile.dart   # CustomPainter
│   │   │       ├── waypoint_list.dart
│   │   │       └── route_stats_bar.dart
│   │   ├── record/
│   │   │   ├── record_screen.dart
│   │   │   ├── recording_service.dart      # foreground task handler
│   │   │   ├── recording_provider.dart
│   │   │   └── widgets/
│   │   │       └── live_stats_grid.dart
│   │   ├── library/
│   │   │   ├── library_screen.dart         # saved routes, tracks, offline regions
│   │   │   ├── track_detail_screen.dart
│   │   │   └── offline_regions_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── shared/
│   │       ├── stat_tile.dart
│   │       ├── condition_badge.dart
│   │       ├── empty_state.dart
│   │       └── attribution_text.dart
│   └── features_flags.dart            # entitlement gates (Phase 9)
├── test/
│   ├── core/geo/                      # unit tests for every geo function
│   ├── domain/usecases/
│   └── data/sources/                  # parsing tests against fixture JSON
├── test/fixtures/
│   ├── overpass_snowgrass.json        # captured real response
│   ├── nifc_perimeters_wa.geojson
│   ├── nws_points.json
│   └── terrarium_tile_14_2640_5787.png
├── android/
│   └── app/src/main/AndroidManifest.xml   # see Section 8.6 for permissions
└── ios/                               # Phase 11
```

---

## 7. Data model (Drift)

`lib/data/db/app_database.dart` skeleton:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// OSM ways: one row per way. Geometry stored as a compact JSON array
// of [lat, lon] pairs to avoid a join on every render.
class OsmWays extends Table {
  Int64Column get id => int64()();                 // OSM way id
  TextColumn get name => text().nullable()();
  TextColumn get highway => text()();              // path, footway, track...
  TextColumn get sacScale => text().nullable()();
  TextColumn get trailVisibility => text().nullable()();
  TextColumn get surface => text().nullable()();
  BoolColumn get informal => boolean().withDefault(const Constant(false))();
  TextColumn get tagsJson => text()();             // full tag map
  TextColumn get geomJson => text()();             // [[lat,lon],...]
  Int64Column get firstNodeId => int64()();
  Int64Column get lastNodeId => int64()();
  RealColumn get lengthM => real()();
  RealColumn get minLat => real()();
  RealColumn get minLon => real()();
  RealColumn get maxLat => real()();
  RealColumn get maxLon => real()();
  TextColumn get usfsName => text().nullable()();  // enrichment from EDW
  TextColumn get usfsNumber => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

// Nodes are only kept where they join two or more ways (graph vertices).
class OsmNodes extends Table {
  Int64Column get id => int64()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  @override Set<Column> get primaryKey => {id};
}

class OsmRelations extends Table {
  Int64Column get id => int64()();
  TextColumn get name => text().nullable()();
  TextColumn get network => text().nullable()();   // lwn, rwn, nwn, iwn
  TextColumn get tagsJson => text()();
  TextColumn get memberWayIdsJson => text()();      // [123, 456]
  @override Set<Column> get primaryKey => {id};
}

class Pois extends Table {
  TextColumn get id => text()();                   // "n123" or "w456"
  TextColumn get kind => text()();                 // spring, peak, camp_site, trailhead...
  TextColumn get name => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get tagsJson => text()();
  @override Set<Column> get primaryKey => {id};
}

class CacheCells extends Table {
  TextColumn get cellKey => text()();              // "z10/163/357"
  TextColumn get dataset => text()();              // ways, pois, usfs, fires
  DateTimeColumn get fetchedAt => dateTime()();
  @override Set<Column> get primaryKey => {cellKey, dataset};
}

class Routes extends Table {
  TextColumn get id => text()();                   // uuid
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get geomJson => text()();             // full snapped polyline
  RealColumn get distanceM => real()();
  RealColumn get gainM => real()();
  RealColumn get lossM => real()();
  RealColumn get maxElevM => real()();
  RealColumn get minElevM => real()();
  TextColumn get notes => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class RouteWaypoints extends Table {
  TextColumn get routeId => text().references(Routes, #id)();
  IntColumn get ordinal => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get label => text().nullable()();
  @override Set<Column> get primaryKey => {routeId, ordinal};
}

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  IntColumn get movingSeconds => integer().withDefault(const Constant(0))();
  IntColumn get totalSeconds => integer().withDefault(const Constant(0))();
  RealColumn get gainM => real().withDefault(const Constant(0))();
  RealColumn get lossM => real().withDefault(const Constant(0))();
  RealColumn get packWeightKg => real().nullable()();
  RealColumn get calories => real().nullable()();
  TextColumn get linkedRouteId => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class TrackPoints extends Table {
  TextColumn get trackId => text().references(Tracks, #id)();
  IntColumn get seq => integer()();
  DateTimeColumn get t => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get gpsAltM => real().nullable()();
  RealColumn get demAltM => real().nullable()();   // filled from terrain tiles
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  @override Set<Column> get primaryKey => {trackId, seq};
}

class OfflineRegions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get minLat => real()();
  RealColumn get minLon => real()();
  RealColumn get maxLat => real()();
  RealColumn get maxLon => real()();
  IntColumn get maplibreRegionId => integer().nullable()();
  TextColumn get styleKey => text()();             // outdoors, topo, satellite
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get status => integer()();             // 0 pending 1 downloading 2 done 3 error
  IntColumn get tileCount => integer().nullable()();
  IntColumn get bytes => integer().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class ConditionsCache extends Table {
  TextColumn get key => text()();                  // "fires:z10/163/357", "nws:46.4623,-121.4512"
  TextColumn get bodyJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  OsmWays, OsmNodes, OsmRelations, Pois, CacheCells,
  Routes, RouteWaypoints, Tracks, TrackPoints, OfflineRegions, ConditionsCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  @override int get schemaVersion => 1;

  static LazyDatabase _open() => LazyDatabase(() async {
        final dir = await getApplicationSupportDirectory();
        return NativeDatabase.createInBackground(File(p.join(dir.path, 'cairn.sqlite')));
      });
}
```

Add indexes in a migration on `OsmWays(minLat, maxLat, minLon, maxLon)` and `Pois(lat, lon)` for bbox lookups. Drift supports `@TableIndex`.

### Cache cell strategy

The world is divided into z10 slippy tiles (each about 20 miles wide at WA latitude). When the map viewport or a route touches a cell that is missing or older than 30 days (ways, POIs, USFS) or 15 minutes (fires) or 60 minutes (weather, AQI), fetch that cell, upsert, record in `CacheCells`. Everything renders from the DB, never directly from the network response. This is what makes offline work: whatever you looked at, you keep.

---

## 8. Phases with code skeletons and acceptance criteria

### Phase 0: Scaffold, theme, l10n, navigation shell

**Files:** `lib/main.dart`, `lib/app.dart`, `lib/core/theme/*`, `lib/core/l10n/l10n_ext.dart`, `lib/core/router/app_router.dart`, `lib/presentation/shell/app_shell.dart`, `lib/l10n/app_en.arb`, `l10n.yaml`, `analysis_options.yaml`, `CLAUDE.md`, `docs/*`.

`lib/core/l10n/l10n_ext.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

`lib/core/theme/app_colors.dart` (see Section 9 for the palette rationale):

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const larch = Color(0xFFD9A441);       // accent, one per surface
  static const glacier = Color(0xFF3FB8AF);     // secondary, water and links
  // Surfaces (dark)
  static const inkDeep = Color(0xFF0E1412);     // near-black with green cast
  static const ink = Color(0xFF15201B);
  static const inkRaised = Color(0xFF1E2C25);
  // Surfaces (light)
  static const paper = Color(0xFFF6F3EC);
  static const paperRaised = Color(0xFFFFFFFF);
  // Semantic (same in both modes, chosen for map legibility)
  static const fire = Color(0xFFE5484D);
  static const smoke = Color(0xFFF5A524);
  static const closure = Color(0xFF8B8B8B);
  static const water = Color(0xFF4A90E2);
  static const route = Color(0xFFD9A441);
  static const track = Color(0xFF3FB8AF);
  static const trailOsm = Color(0xFF6B4F2A);    // brown, like a paper map
  static const trailInformal = Color(0xFF9C8A6E);
}
```

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.larch,
      brightness: Brightness.dark,
      surface: AppColors.ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.inkDeep,
      textTheme: AppTypography.textTheme(scheme),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.larch.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: const CardThemeData(elevation: 0),
    );
  }

  static ThemeData light() { /* mirror of dark() with paper surfaces */ }
}
```

`lib/core/router/app_router.dart`:

```dart
final appRouter = GoRouter(
  initialLocation: '/map',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/map', builder: (_, __) => const MapScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/plan', builder: (_, __) => const PlanScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/record', builder: (_, __) => const RecordScreen())]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/library', builder: (_, __) => const LibraryScreen(), routes: [
            GoRoute(path: 'track/:id', builder: (_, s) => TrackDetailScreen(id: s.pathParameters['id']!)),
            GoRoute(path: 'offline', builder: (_, __) => const OfflineRegionsScreen()),
            GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ]),
      ],
    ),
  ],
);
```

**Acceptance (Phase 0):**
- [ ] `flutter run` on a physical Android device shows a 4-tab shell (Map, Plan, Record, Library) with placeholder screens
- [ ] Dark and light themes both render; toggling system theme switches live
- [ ] `context.l10n.appName` resolves; zero hardcoded strings in `lib/` (grep for `Text('` and `Text("` returns only l10n calls)
- [ ] `flutter analyze` clean, `flutter test` passes (one smoke test)
- [ ] `CLAUDE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` exist and are filled in
- [ ] `LICENSE` (GPL-3.0-or-later), `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/` exist; `.gitignore` covers keystores, `debug-symbols/`, `.env`
- [ ] Every Dart file has the SPDX header; `tool/check_spdx.sh` passes
- [ ] Both flavors build: `flutter build apk --flavor community --debug` and `flutter build apk --flavor store --debug --dart-define=CAIRN_STORE=true`
- [ ] GitHub Actions workflow runs analyze + test on push and builds the community APK on tags
- [ ] Commit `phase-0: scaffold`

---

### Phase 1: Map core

**Goal:** Full-screen MapLibre map with three switchable styles (Outdoors, Topo, Satellite), hillshade, user location puck, compass, scale bar, attribution, and a layer switcher sheet.

**Files:** `assets/map_styles/*.json`, `lib/presentation/map/map_screen.dart`, `map_controller_provider.dart`, `widgets/layer_switcher_sheet.dart`, `widgets/location_fab.dart`, `lib/presentation/shared/attribution_text.dart`.

`assets/map_styles/topo.json` (raster USGS + terrain DEM + empty sources our layers will fill):

```json
{
  "version": 8,
  "name": "Cairn Topo",
  "sources": {
    "usgs-topo": {
      "type": "raster",
      "tiles": ["https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}"],
      "tileSize": 256,
      "maxzoom": 16,
      "attribution": "USGS The National Map"
    },
    "terrain-dem": {
      "type": "raster-dem",
      "tiles": ["https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "encoding": "terrarium",
      "minzoom": 0,
      "maxzoom": 15,
      "attribution": "Terrain: Mapzen / AWS Terrain Tiles"
    },
    "cairn-trails": { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } },
    "cairn-pois":   { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } },
    "cairn-fires":  { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } },
    "cairn-land":   { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } },
    "cairn-route":  { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } },
    "cairn-track":  { "type": "geojson", "data": { "type": "FeatureCollection", "features": [] } }
  },
  "layers": [
    { "id": "usgs-topo", "type": "raster", "source": "usgs-topo" },
    { "id": "hillshade", "type": "hillshade", "source": "terrain-dem",
      "paint": { "hillshade-exaggeration": 0.35, "hillshade-shadow-color": "#2b2b2b" } },
    { "id": "land-fill", "type": "fill", "source": "cairn-land",
      "paint": { "fill-color": ["get", "fill"], "fill-opacity": 0.12 } },
    { "id": "land-line", "type": "line", "source": "cairn-land",
      "paint": { "line-color": ["get", "stroke"], "line-width": 1.5, "line-dasharray": [3, 2] } },
    { "id": "fires-fill", "type": "fill", "source": "cairn-fires",
      "paint": { "fill-color": "#E5484D", "fill-opacity": 0.28 } },
    { "id": "fires-line", "type": "line", "source": "cairn-fires",
      "paint": { "line-color": "#E5484D", "line-width": 2 } },
    { "id": "trails-casing", "type": "line", "source": "cairn-trails",
      "paint": { "line-color": "#F6F3EC", "line-width": 4, "line-opacity": 0.7 } },
    { "id": "trails", "type": "line", "source": "cairn-trails",
      "paint": { "line-color": ["case", ["==", ["get", "informal"], true], "#9C8A6E", "#6B4F2A"],
                 "line-width": ["interpolate", ["linear"], ["zoom"], 10, 1, 14, 2.5, 17, 4],
                 "line-dasharray": ["case", ["==", ["get", "informal"], true], ["literal", [2, 2]], ["literal", [1, 0]]] } },
    { "id": "route-casing", "type": "line", "source": "cairn-route",
      "paint": { "line-color": "#0E1412", "line-width": 7, "line-opacity": 0.6 } },
    { "id": "route", "type": "line", "source": "cairn-route",
      "paint": { "line-color": "#D9A441", "line-width": 4 } },
    { "id": "track", "type": "line", "source": "cairn-track",
      "paint": { "line-color": "#3FB8AF", "line-width": 3.5 } },
    { "id": "pois", "type": "symbol", "source": "cairn-pois",
      "layout": { "icon-image": ["get", "icon"], "icon-size": 0.9, "icon-allow-overlap": false,
                  "text-field": ["get", "name"], "text-size": 11, "text-offset": [0, 1.2], "text-optional": true },
      "paint": { "text-halo-color": "#F6F3EC", "text-halo-width": 1.2 } }
  ]
}
```

`outdoors.json`: same, but the base is OpenFreeMap. Because OpenFreeMap serves a full style, the simplest path is: fetch `https://tiles.openfreemap.org/styles/liberty` once at build time (a script in `tool/fetch_styles.dart`), save it as the base, then append the `terrain-dem` source, `hillshade` layer (insert after the last landuse/water layer and before roads), and the six `cairn-*` sources and layers. Do not hotlink the remote style at runtime; a local copy means offline styles just work. `satellite.json`: USGS Imagery raster + hillshade at 0.2 exaggeration + the same overlay layers, labels in white with dark halo.

POI icons: add 10 simple SVG-rendered icons to the style sprite (spring, water, peak, saddle, camp, hut, viewpoint, toilets, parking, trailhead). MapLibre needs a sprite; generate one with `spreet` or `spritezero` from `assets/icons/*.svg` in `tool/build_sprite.sh` and host it under `assets/map_styles/sprite` (MapLibre can load `asset://` sprites via the plugin's asset handling; if not, add the images at runtime with `controller.addImage`).

`lib/presentation/map/map_screen.dart` skeleton:

```dart
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _c;

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(mapStyleProvider);          // outdoors | topo | satellite
    return Scaffold(
      body: Stack(children: [
        MapLibreMap(
          styleString: style.assetPath,                   // 'assets/map_styles/topo.json'
          initialCameraPosition: const CameraPosition(target: LatLng(46.75, -121.5), zoom: 9),
          myLocationEnabled: true,
          myLocationRenderMode: MyLocationRenderMode.compass,
          compassEnabled: true,
          onMapCreated: (c) { _c = c; ref.read(mapControllerProvider.notifier).attach(c); },
          onStyleLoadedCallback: () => ref.read(mapLayersProvider.notifier).installAll(),
          onCameraIdle: () => ref.read(viewportProvider.notifier).update(_c!),
          onMapClick: (_, latLng) => ref.read(mapTapProvider.notifier).handle(latLng),
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
        ),
        const Positioned(right: 16, bottom: 96, child: LocationFab()),
        const Positioned(right: 16, top: 56, child: LayerSwitcherButton()),
        const Align(alignment: Alignment.bottomCenter, child: MapBottomPanel()),
      ]),
    );
  }
}
```

`viewportProvider` exposes the current visible bbox and zoom. Every data layer watches it and requests cells accordingly (debounced 400 ms).

**Acceptance (Phase 1):**
- [ ] Map renders on device with each of the three styles; style switch keeps camera position
- [ ] Hillshade visible on Topo and Outdoors at zoom 11+
- [ ] Location permission requested at first tap of the location FAB (not at app launch); puck appears; FAB recenters
- [ ] Compass rotates the map; tapping it resets north
- [ ] Attribution control shows OSM, USGS, Mapzen/AWS as appropriate for the active style
- [ ] Camera position and active style persist across app restarts (SharedPreferences)
- [ ] Pinch, rotate, tilt all work at 60 fps on a mid-range Android device
- [ ] Commit `phase-1: map core`

---

### Phase 2: Trails and POIs on the map

**Goal:** Trails from OSM render as a GeoJSON layer within a second of panning to a new area, get cached in Drift, and a tap on a trail opens a detail sheet with name, USFS number if matched, length of the tapped way, surface, and SAC scale.

**Files:** `lib/data/sources/overpass_source.dart`, `usfs_source.dart`, `lib/data/repositories/trail_repository_impl.dart`, `poi_repository_impl.dart`, `lib/presentation/map/layers/trails_layer.dart`, `pois_layer.dart`, `widgets/trail_detail_sheet.dart`, `lib/core/geo/tile_math.dart`, `haversine.dart`.

`lib/core/geo/tile_math.dart`:

```dart
import 'dart:math' as math;

class TileXY { final int x, y, z; const TileXY(this.x, this.y, this.z); String get key => 'z$z/$x/$y'; }

TileXY latLonToTile(double lat, double lon, int z) {
  final n = math.pow(2, z).toDouble();
  final x = ((lon + 180) / 360 * n).floor();
  final latRad = lat * math.pi / 180;
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
  return TileXY(x, y, z);
}

/// Returns (south, west, north, east) for a tile.
List<double> tileBounds(TileXY t) {
  final n = math.pow(2, t.z).toDouble();
  double lonOf(int x) => x / n * 360 - 180;
  double latOf(int y) { final a = math.pi - 2 * math.pi * y / n; return 180 / math.pi * math.atan(0.5 * (math.exp(a) - math.exp(-a))); }
  return [latOf(t.y + 1), lonOf(t.x), latOf(t.y), lonOf(t.x + 1)];
}

/// Fractional pixel position of a coordinate inside a 256px tile at zoom z.
({TileXY tile, double px, double py}) latLonToPixel(double lat, double lon, int z) {
  final n = math.pow(2, z).toDouble();
  final xf = (lon + 180) / 360 * n;
  final latRad = lat * math.pi / 180;
  final yf = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
  final tile = TileXY(xf.floor(), yf.floor(), z);
  return (tile: tile, px: (xf - tile.x) * 256, py: (yf - tile.y) * 256);
}
```

`lib/data/sources/overpass_source.dart`:

```dart
class OverpassSource {
  OverpassSource(this._dio);
  final Dio _dio;
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  Future<OverpassResponse> fetchWays(List<double> bbox) => _run(_waysQuery(bbox));
  Future<OverpassResponse> fetchPois(List<double> bbox) => _run(_poisQuery(bbox));

  Future<OverpassResponse> _run(String q) async {
    Object? lastErr;
    for (final ep in _endpoints) {
      try {
        final r = await _dio.post(ep, data: {'data': q},
            options: Options(contentType: Headers.formUrlEncodedContentType,
                             receiveTimeout: const Duration(seconds: 90)));
        return OverpassResponse.fromJson(r.data as Map<String, dynamic>);
      } on DioException catch (e) {
        lastErr = e;
        if (e.response?.statusCode == 429 || e.response?.statusCode == 504) continue;
        rethrow;
      }
    }
    throw OverpassUnavailable(lastErr);
  }

  String _waysQuery(List<double> b) => '''
[out:json][timeout:60];
(
  way["highway"~"^(path|footway|track|bridleway|steps)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
  relation["route"~"^(hiking|foot)\$"](${b[0]},${b[1]},${b[2]},${b[3]});
);
out body;
>;
out skel qt;''';
}
```

Ingest: build a node map from the response, then for each way resolve its node list into `[[lat,lon],...]`, compute `lengthM` with haversine, compute bbox, keep `firstNodeId`/`lastNodeId`, and record every node id that appears in two or more ways into `OsmNodes` (these are the graph vertices for Phase 3 routing). Upsert in one transaction per cell.

Rendering: `TrailsLayer` watches `viewportProvider`, queries Drift for ways whose bbox intersects the viewport, builds a `FeatureCollection` and calls `controller.setGeoJsonSource('cairn-trails', fc)`. Cap at 4,000 features per update; if over, simplify geometry with Douglas-Peucker (tolerance scaled by zoom) before serializing. Above zoom 15 send full geometry.

USFS enrichment: after ingesting a cell, query the EDW trails layer for the same bbox, and for each USFS feature find OSM ways within 25 m along at least 60% of their length (sample 10 points along the USFS line, nearest OSM way for each, majority vote). Write `usfsName` and `usfsNumber`. Run this in an isolate; it is not on the render path.

Tap handling: `controller.queryRenderedFeatures(point, ['trails', 'pois'], null)`. If a trail was hit, open `TrailDetailSheet` (DraggableScrollableSheet, snap points 0.25, 0.6, 0.95). Sheet contents in order: name (or "Unnamed path"), USFS number chip, this segment's length, surface, SAC scale with a plain-English label (see l10n keys `sac_hiking` etc.), a "Plan a route from here" button, and a "Show on map" that flashes the whole relation if the way is part of a named route.

**Acceptance (Phase 2):**
- [ ] Pan to Goat Rocks (46.47, -121.45) at zoom 12: Snowgrass Trail, Goat Ridge Trail, PCT render within 2 s on a cold cache, instantly on warm cache
- [ ] Kill the network (airplane mode), restart the app, pan to the same area: trails still render
- [ ] Tapping the PCT opens the sheet with name "Pacific Crest Trail" and (after enrichment) USFS number 2000
- [ ] Springs, lakes, peaks, campsites, trailheads show as icons with labels at zoom 13+
- [ ] Overpass 429 falls back to a mirror; a total failure shows a non-blocking banner (l10n `trails_offline_banner`) and the map keeps working with cached data
- [ ] Unit tests: `tile_math` round trips 20 random coordinates; haversine matches known distances within 0.1%; Overpass fixture parses to the expected number of ways
- [ ] Commit `phase-2: trails`

---

### Phase 3: Route planner with snap-to-trail and elevation profile

**Goal:** Tap to add waypoints; each waypoint snaps to the nearest trail within 40 m; the route between consecutive waypoints follows the trail graph (Dijkstra over OSM ways); a live stats bar shows distance, gain, loss, high point; an elevation profile draws under the map; tapping the profile highlights the point on the map.

**Files:** `lib/domain/usecases/snap_to_trail.dart`, `route_between_waypoints.dart`, `compute_route_stats.dart`, `lib/core/geo/elevation_stats.dart`, `terrarium.dart`, `lib/data/sources/terrain_tile_source.dart`, `lib/data/repositories/elevation_repository_impl.dart`, `lib/presentation/plan/*`.

`lib/core/geo/terrarium.dart`:

```dart
double terrariumToMeters(int r, int g, int b) => (r * 256 + g + b / 256) - 32768;
```

`lib/data/sources/terrain_tile_source.dart`:

```dart
/// Fetches terrarium PNG tiles at a fixed zoom (14) and caches them on disk under
/// <support>/terrain/14/x/y.png. Decodes to a Uint16List of elevations (meters * 10,
/// offset so negatives fit) so repeated lookups do not re-decode.
class TerrainTileSource {
  static const zoom = 14;
  final Dio _dio; final Directory _dir; final _mem = <String, Float32List>{};

  Future<Float32List> tile(TileXY t) async { /* memory -> disk -> network */ }

  Future<double> elevationAt(double lat, double lon) async {
    final p = latLonToPixel(lat, lon, zoom);
    final grid = await tile(p.tile);
    // bilinear interpolation across the 256x256 grid
    return bilinear(grid, p.px, p.py);
  }

  /// Batch: groups coordinates by tile so a 20 mile route touches ~12 tiles, not 12,000 lookups.
  Future<List<double>> elevations(List<LatLng> pts) async { /* group by tile, decode once */ }
}
```

Elevation for a route: resample the polyline every 20 m (`turf.along`), look up DEM elevation for each sample, then compute gain and loss with **hysteresis**: only count a climb once cumulative rise since the last local minimum exceeds 5 m, same for descent. Without this, DEM noise adds hundreds of phantom feet. `elevation_stats.dart`:

```dart
({double gain, double loss, double maxElev, double minElev}) gainLoss(List<double> elev, {double threshold = 5.0}) {
  var gain = 0.0, loss = 0.0;
  var ref = elev.first; var dir = 0; // 1 up, -1 down
  for (final e in elev.skip(1)) {
    final d = e - ref;
    if (dir >= 0 && d >= threshold) { gain += d; ref = e; dir = 1; }
    else if (dir <= 0 && d <= -threshold) { loss += -d; ref = e; dir = -1; }
    else if (dir == 1 && e > ref) { gain += e - ref; ref = e; }
    else if (dir == -1 && e < ref) { loss += ref - e; ref = e; }
  }
  return (gain: gain, loss: loss, maxElev: elev.reduce(math.max), minElev: elev.reduce(math.min));
}
```

Snap: `turf.nearestPointOnLine` against every cached way whose bbox is within 40 m of the tap (expand the tap bbox, query Drift). Keep the way id and the segment index so the router knows where on the graph the waypoint sits.

Routing between waypoints: build an in-memory graph from cached ways in the bbox of the two waypoints (expanded by 2 km). Vertices are `OsmNodes` (shared nodes) plus the two snapped points (split their ways). Edge weight = length in meters, multiplied by 1.4 for `informal=yes`, 3.0 for `sac_scale` of `difficult_alpine_hiking` or harder, and infinity for `access=private`. Dijkstra with a binary heap. If no path exists within the graph, fall back to a straight line between the waypoints and mark that leg `offTrail: true` (render dashed). Never silently draw a straight line without the flag.

Elevation profile widget (`elevation_profile.dart`): `CustomPainter`, x = distance, y = elevation, filled area under the line, gradient by grade (green under 8%, amber 8 to 15%, red over 15%), a draggable scrubber that emits the distance; the plan provider maps that distance to a coordinate and moves a marker on the map. Show max/min labels. Height 140 dp. Must render 5,000 points without jank (downsample to the widget's pixel width first).

Stats bar: distance, gain, loss, high point, estimated time. Time estimate = Naismith with Langmuir corrections: 1 hour per 5 km + 1 hour per 600 m of ascent, minus 10 min per 300 m of gentle descent, plus 10 min per 300 m of steep descent (grade over 20%). Show as "est. 6h 20m". Do not overclaim precision.

Waypoint UX: tap map to add, long-press a waypoint to drag it, swipe a waypoint row in the list to delete, tap a route leg to insert a waypoint mid-leg. Undo stack of 20.

Save: name dialog, writes `Routes` + `RouteWaypoints`, appears in Library.

**Acceptance (Phase 3):**
- [ ] Plan Berry Patch TH to Snowgrass Flats to Goat Lake and back with 5 waypoints: distance within 5% of AllTrails' 12.4 mi, gain within 10% of 2,706 ft
- [ ] Every leg follows the trail line, no shortcuts across contour lines; an intentionally off-trail waypoint produces a dashed leg with an "off trail" chip in the list
- [ ] Profile scrubber moves the map marker; dragging a waypoint recomputes in under 500 ms for a 15 mile route on a warm cache
- [ ] Airplane mode: planning works entirely from cached ways and cached terrain tiles for an area previously viewed
- [ ] Unit tests: `gainLoss` on a synthetic sawtooth returns exact values; Dijkstra on a 5-node fixture graph picks the known shortest path; terrarium decode of the fixture tile at a known pixel equals the known elevation within 1 m
- [ ] Commit `phase-3: planner`

---

### Phase 4: GPX import and export, Library

**Goal:** Import GPX files (from CalTopo, Wikiloc, AllTrails exports, Garmin); render them; save as a route or a track; export any route or track as GPX; share sheet.

**Files:** `lib/data/gpx/gpx_codec.dart`, `lib/presentation/library/*`.

Import via `file_picker` (allowed extensions gpx) and via Android intent filter for `application/gpx+xml` and `.gpx` (add to manifest so "Open with Cairn" works from a browser download). Parse with `package:gpx`. `<trk>` becomes a Track (with timestamps if present, otherwise a route-like track with no times), `<rte>` becomes a Route (waypoints = rtept), `<wpt>` become user POIs attached to the route. Compute stats with the same use cases as Phase 3 (DEM elevation, not the GPX `<ele>`, which is often garbage; keep GPX ele as `gpsAltM`).

Export: `GpxWriter().asString(gpx)` with creator `Cairn`, include `<ele>` from DEM, `<time>` for tracks, share via `share_plus` as `<name>.gpx`.

Library screen: three tabs (Routes, Tracks, Offline). Each row: name, date, distance, gain, tiny sparkline of the profile. Swipe to delete with undo snackbar. Tap opens detail with the map focused on the geometry and the full profile.

**Acceptance (Phase 4):**
- [ ] Import the CalTopo GPX of a known route; distance and gain match Phase 3's numbers for the same line within 3%
- [ ] A GPX opened from Chrome's download bar launches Cairn on the import screen
- [ ] Export a planned route, re-import it, geometry identical (point count and coordinates)
- [ ] Malformed GPX shows l10n `gpx_import_failed` and does not crash
- [ ] Commit `phase-4: gpx and library`

---

### Phase 5: Offline regions

**Goal:** Draw a rectangle (or "this route plus 3 miles"), pick styles and max zoom, see an estimate, download. Afterward the map, trails, POIs, and elevation all work in airplane mode inside that region.

**Files:** `lib/data/repositories/offline_repository_impl.dart`, `lib/presentation/library/offline_regions_screen.dart`, `lib/presentation/map/widgets/region_picker_overlay.dart`.

Four things get downloaded per region:

1. **Basemap tiles** via `controller.downloadOfflineRegion(OfflineRegionDefinition(bounds:, mapStyleUrl:, minZoom:, maxZoom:), metadata: {...}, onEvent:)`. One MapLibre region per style the user selected. Store the returned region id.
2. **Terrain tiles** at z14 for the bbox via `TerrainTileSource` (these are shared with Phase 3's cache).
3. **Trail and POI cells** at z10 covering the bbox via the Phase 2 fetchers, forced refresh.
4. **USFS land polygons** (wilderness, forest boundaries) for the bbox.

Estimate before download: tile count = sum over zooms of tiles in bbox; assume 25 KB per vector tile, 60 KB per raster tile, 30 KB per terrain tile. Show "about 140 MB". Warn over 1 GB. Show live progress per part. Downloads run in a foreground task so they survive backgrounding; the notification shows percent.

Default max zoom 14 for Outdoors (vector tiles overzoom cleanly to 18), 15 for Topo and Satellite raster. Expose a slider 12 to 16.

Region management: list with size, date, style badges, "Refresh" (re-download trails and conditions only), "Delete" (calls `deleteOfflineRegion` and removes terrain tiles not referenced by another region).

**Acceptance (Phase 5):**
- [ ] Download a 20 x 20 mile region around Mt. Adams at max zoom 14, Outdoors + Topo: completes, size within 30% of the estimate
- [ ] Airplane mode: pan, zoom, tap trails, plan a route, view elevation profile, all inside the region, zero network calls (verify with `adb shell dumpsys netstats` or Dio logging)
- [ ] App killed mid-download, reopened: region shows "incomplete", "Resume" works
- [ ] Deleting a region frees the reported bytes (check `du` on the app data dir)
- [ ] Commit `phase-5: offline`

---

### Phase 6: Track recording

**Goal:** Start, pause, resume, stop. Live stats: distance, moving time, total time, pace, current speed, gain, current elevation. Runs with the screen off via a foreground service. Auto-pause when stationary. Saves to Library. Optionally follows a planned route with off-route warning.

**Files:** `lib/presentation/record/recording_service.dart` (top-level `@pragma('vm:entry-point') void startCallback()` + `TaskHandler`), `recording_provider.dart`, `record_screen.dart`, `widgets/live_stats_grid.dart`, `lib/domain/usecases/trip_calories.dart`.

Location config: `geolocator` `LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5)` on Android use `AndroidSettings(foregroundNotificationConfig:)` OR run the stream inside the `flutter_foreground_task` handler and send points to the UI via `FlutterForegroundTask.sendDataToMain`. Prefer the foreground task approach: the handler owns the Drift write, the UI just reads.

Filtering: drop points with `accuracy > 30 m`; drop points that imply speed over 12 m/s (GPS jumps); moving time accrues only when speed over the last 10 s exceeds 0.5 m/s. Elevation for gain uses DEM (`demAltM`) when the tile is cached, else GPS altitude smoothed with a 5-point median; gain uses the same hysteresis as Phase 3.

Calories (`trip_calories.dart`): Pandolf equation for load carriage. Inputs: body mass (settings, optional), pack mass (per-track prompt, remembers last), speed, grade from DEM. `M = 1.5W + 2.0(W+L)(L/W)^2 + n(W+L)(1.5V^2 + 0.35VG)` in watts, integrate over time, convert to kcal. If body mass unset, use 75 kg and label the number "estimate".

Follow mode: pick a saved route; the record screen shows distance remaining, ETA using your own moving pace, and an off-route banner (haptic medium) when the nearest route point is more than 60 m away for 30 s.

Notification: "Recording: 6.2 mi, 2h 14m" updated every 15 s. Tapping opens the Record tab. Stop button action on the notification.

**Acceptance (Phase 6):**
- [ ] A 1 hour walk with screen off records continuously; point count roughly one per 5 to 10 m
- [ ] Killing the app from recents while recording: the service keeps recording; reopening shows the live session
- [ ] Auto-pause triggers within 20 s of standing still; resumes within 5 s of walking
- [ ] Distance on a known 1.0 mile loop within 2%
- [ ] Exported GPX opens in CalTopo with correct timestamps
- [ ] Android 14+: manifest declares `FOREGROUND_SERVICE_LOCATION`, service `foregroundServiceType="location"`, and the app requests `ACCESS_BACKGROUND_LOCATION` only when the user starts a recording (not at first launch)
- [ ] Commit `phase-6: recording`

---

### Phase 7: Conditions overlay (the reason this app exists)

**Goal:** A "Conditions" toggle on the map and a panel on any route or trail showing: fires, air quality, weather at trailhead and high point, NWS alerts, daylight and moon.

**Files:** `lib/data/sources/nifc_source.dart`, `nws_source.dart`, `open_meteo_source.dart`, `lib/data/repositories/conditions_repository_impl.dart`, `lib/presentation/map/layers/fires_layer.dart`, `land_layer.dart`, `widgets/conditions_panel.dart`, `lib/core/geo/solar.dart`, `moon.dart`.

**Fires:** query both NIFC layers for the viewport bbox (plus a 50 mile buffer so a fire just off-screen still shows) every 15 min while the map is open. Perimeters render as translucent red fill with a solid edge; incident points as a flame icon sized by acres (log scale). Tap opens a card: name, acres, percent contained, discovered date, last update ("updated 12 min ago"), fire behavior text, and a button "Open on InciWeb" (URL-launch search). Prescribed burns (`RX`) render amber, not red.

**Route intersection:** for a planned route or a saved track, compute distance from the route to the nearest perimeter (`turf` point-in-polygon on samples plus distance to polygon boundary). Show one of: "Route crosses the X Fire perimeter", "X Fire is 4.2 mi from the route", or "No active fires within 50 mi". Red, amber, green badge respectively (thresholds: crosses, under 10 mi, otherwise).

**Air quality:** Open-Meteo hourly `us_aqi` for the trailhead and the high point. Show current AQI with the EPA category and color (Good 0 to 50 green, Moderate 51 to 100 yellow, USG 101 to 150 orange, Unhealthy 151 to 200 red, Very Unhealthy 201 to 300 purple, Hazardous 301+ maroon). Show a 3-day sparkline. Copy under it: "Model estimate. Monitor data in a later update." Phase 8 swaps in AirNow.

**Weather:** NWS hourly for trailhead and high point, 48 hours: temp, precip chance, wind and gusts, sky. Show a compact two-row strip (trailhead over high point) so the temperature difference is obvious. NWS active alerts for the route's bbox as red or amber banners (Red Flag Warning is red; heat, wind, winter storm are amber). Fallback to Open-Meteo if NWS 5xx or if outside the US.

**Daylight and moon:** `solar.dart` implements the NOAA solar position algorithm: sunrise, sunset, civil twilight for a date and coordinate. `moon.dart`: phase and illumination percentage (Meeus, simplified). Panel shows "Sunrise 6:24, sunset 7:52, 13h 28m of daylight, moon 17% waxing crescent". This matters for headlamp planning and for the bioluminescence use case.

**Land layer:** wilderness polygons (dashed green edge, faint fill) and forest boundaries (dashed brown). When a planned route enters a wilderness, the panel adds "Enters Goat Rocks Wilderness: free self-issue permit at the trailhead" (text from a small lookup in `assets/data/wa_parks.json` keyed by wilderness name, fallback generic). When a route enters a National Park boundary (EDW does not have NPS; use the NPS boundary layer at `https://services1.arcgis.com/fBc8EJBxQRMcHlei/arcgis/rest/services/NPS_Land_Resources_Division_Boundary_and_Tract_Data_Service/FeatureServer/2`, verify live), show "Mount Rainier National Park: entrance fee or America the Beautiful pass".

**Freshness rules:** every card shows when its data was fetched. Anything older than 6 hours gets a grey "stale" chip. Offline: show cached conditions with the stale chip and the time; never hide them.

**Acceptance (Phase 7):**
- [ ] With the map on the Cascades, active WFIGS perimeters render and the incident card fields match the NIFC web map for the same fire
- [ ] A planned route through a known perimeter shows the red "crosses" badge; a route 20 mi away shows green
- [ ] AQI category colors match EPA breakpoints (unit test on 8 boundary values)
- [ ] NWS request without User-Agent is impossible (the Dio client injects it); a 403 from NWS falls back to Open-Meteo
- [ ] Sunrise and sunset for Tacoma on 2026-09-10 match timeanddate.com within 2 minutes; moon illumination on 2026-07-25 matches within 3 points
- [ ] Wilderness entry callout appears for the Snowgrass loop
- [ ] Airplane mode: conditions panel shows the last fetched data with the stale chip and fetch time
- [ ] Commit `phase-7: conditions`

---

### Phase 8: Trip helpers and the Affluent Labs proxy

**Goal:** Water sources along a route with distance markers, "last water before" callout, campsite suggestions, trailhead parking with pass requirement, and the tiny proxy for keyed APIs.

**Water along route** (`water_along_route.dart`): for each POI of kind spring, drinking_water, stream crossing (route intersects an OSM waterway), lake shore (route within 80 m of `natural=water`), compute the distance along the route. Render as small blue ticks on the elevation profile and a list "Water: 0.0 mi Goat Creek, 4.6 mi Snowgrass Creek (last before the climb to 7,800 ft), 9.1 mi Goat Lake". "Last before the climb" = the last water source before the longest sustained ascent segment. Seasonal caveat text on every water list: "Seasonal streams may be dry in late summer."

**Campsites:** OSM `tourism=camp_site` and `backcountry=yes` nodes within 300 m of the route with distance-along. If inside a wilderness, add the generic "camp 200 ft from water and trail" reminder.

**Trailhead parking:** OSM `highway=trailhead` and `amenity=parking` near route start; if inside a National Forest boundary, show "Northwest Forest Pass or America the Beautiful"; if inside NPS, "Park entrance fee or America the Beautiful"; if inside a WA State Park (WA DNR/State Parks boundaries from `https://services.arcgis.com/6lCKYNJLvwTXqrmp/arcgis/rest/services/WA_State_Parks_Boundaries/FeatureServer` , verify live, else skip), "Discover Pass". Store the rule table in `assets/data/wa_parks.json` so it is editable without a code change.

**Proxy** (Node or Go, deployed on the existing Affluent Labs Linux box behind nginx, same pattern as `zestssh-api`):
- `GET /v1/aqi?lat=&lon=` -> AirNow `ziplatlong` current observations, cached 30 min per 0.05° grid cell
- `GET /v1/nps/alerts?parks=mora,olym,noca` -> NPS API, cached 30 min
- `GET /v1/ridb/facilities?lat=&lon=&radius=` -> RIDB, cached 24 h
- `GET /v1/restrictions.json` -> static file maintained by hand:

```json
{
  "updated": "2026-09-10",
  "units": [
    { "name": "Gifford Pinchot National Forest", "stage": 1,
      "summary": "Stage 1: no campfires outside developed campground fire rings. Gas stoves OK.",
      "source": "https://www.fs.usda.gov/r06/giffordpinchot/alerts", "since": "2026-06-26" },
    { "name": "Mount Rainier National Park", "stage": 0, "summary": "No restrictions posted.", "source": "https://www.nps.gov/mora/planyourvisit/conditions.htm" }
  ]
}
```

Rate limit the proxy per IP (60/min), no auth needed because it only serves cached public data. App calls it over HTTPS only; if the proxy is down, the app degrades to the no-key sources and says so.

**Acceptance (Phase 8):**
- [ ] Snowgrass loop shows Goat Creek, Snowgrass Creek, Goat Lake as water with correct order and distances within 0.2 mi
- [ ] Proxy returns AirNow AQI for Packwood and the app prefers it over Open-Meteo, labeled "EPA AirNow monitor"
- [ ] Proxy unreachable: app shows Open-Meteo values with the "model estimate" label, no error dialog
- [ ] `restrictions.json` stage shows on the conditions panel for a route in Gifford Pinchot
- [ ] Commit `phase-8: trip helpers`

---

### Phase 9: Settings, entitlements, privacy, release hardening

**Settings:** units (imperial/metric), theme (system/dark/light), default map style, body weight (optional, for calories), default pack weight, terrain tile cache size with a clear button, "Data sources and attribution" page, "Privacy" page (plain text from `docs/PRIVACY.md`), version and licenses (`showLicensePage`).

**Entitlements** (`lib/features_flags.dart`): the Affluent Labs pattern is free core plus a one-time unlock. Proposed split, confirm with the user before Play Store launch, but build it gated so it can flip either way:

- Free: everything in Phases 1 to 4, 6, 7; one offline region up to 500 MB
- Cairn Summit (one-time, USD 9.99): unlimited offline regions, water and campsite helpers, follow-route mode, AirNow monitor data

RevenueCat via `purchases_flutter`, product id `cairn_summit_lifetime`. Google sign-in only for restore. In debug builds every gate is open. Never block map viewing, trail browsing, or recording behind the paywall.

**Privacy (write `docs/PRIVACY.md`):** no account, no analytics, no ads. Location is used for the puck and recordings and stays on the device. Network requests send only coordinates or a map area to the public data sources listed, plus the Affluent Labs proxy which logs nothing but a rate-limit counter. GPX files you export are yours.

**Security checklist (from the Affluent Labs pre-release audit):**
- [ ] `android:usesCleartextTraffic="false"`; network security config blocks HTTP
- [ ] `android:allowBackup="false"` (tracks are exportable as GPX; do not rely on auto-backup)
- [ ] Release build uses `--obfuscate --split-debug-info`; symbols folder gitignored, kept locally
- [ ] No API keys in the binary: grep the built APK strings for `airnow`, `nps.gov/api` keys, RIDB key; must be zero hits
- [ ] `debuggable=false` in release; all `debugPrint` gated on `kDebugMode`
- [ ] Only these permissions: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (requested at recording start only), `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`. Nothing else.
- [ ] Exported components: none except the GPX intent filter activity; `exported="true"` only on that activity
- [ ] `flutter_secure_storage` for the RevenueCat app user id; `shared_preferences` only for settings
- [ ] Dio interceptors do not log request URLs in release (they contain coordinates)
- [ ] Deep link (GPX import) validates the file is under 20 MB and parses as XML before doing anything else
- [ ] Third-party plugin permission review written into `docs/DECISIONS.md`
- [ ] `pubspec.lock` committed

**Play Console prep:** foreground service location use-case declaration and a 30 second screen recording of the recording feature (Google requires it). Data safety form: location collected, not shared, on-device.

**Acceptance (Phase 9):**
- [ ] All settings persist and apply immediately
- [ ] Community release build: every feature open, no Summit UI anywhere, `apkanalyzer` (or `aapt dump badging`) shows no Play Billing, Play Services, or Firebase classes
- [ ] Store release build with no purchase: second offline region shows the Summit sheet, map, fires, weather, and recording untouched
- [ ] Store build: purchase, uninstall, reinstall, restore: entitlement returns
- [ ] Security checklist fully ticked in `docs/PROGRESS.md` with evidence (command output pasted)
- [ ] `docs/LICENSES.md` lists every direct dependency and its license; all GPL-3 compatible
- [ ] `tool/build.sh` produces both artifacts: community APK (under 35 MB, signed with the community keystore) and store AAB (under 40 MB), both obfuscated with symbols kept locally
- [ ] Tagging `v0.1.0` produces a GitHub Release with the community APK and its SHA-256 attached by CI
- [ ] `metadata/en-US/` is complete for F-Droid: descriptions, changelog for 0.1.0, at least four screenshots
- [ ] Commit `phase-9: release candidate`

---

### Phase 10 and beyond (backlog, do not start without the user)

- Self-hosted PMTiles basemap and WA trails tileset (Section 5.9) to drop Overpass at runtime
- iOS build (MapLibre iOS, background location entitlements, ATS)
- Share a route as a link (proxy stores GPX under a random id, 30 day TTL)
- Wear OS companion showing live stats
- Trip checklist per route (gear list keyed to nights, water carry advice from the water helper)
- Community condition reports, opt-in, still no account (device-generated key pair)
- Avalanche layer (NWAC) for shoulder season
- Snow depth (SNOTEL via USDA NRCS API) for early-season access questions
- Trailhead drive time and "last gas" from OSM

---

## 9. Design system and mockups

### 9.1 Direction

It should feel like a good paper topo map and a well-worn field notebook, not a fitness app. Warm neutrals, one gold accent (larch needles in October), teal only for water and the recorded track. Dark mode is the default hero because this gets used at 4 AM in a car and at camp at dusk. Nothing glows. Nothing bounces for no reason.

References to beat: Gaia GPS (cluttered), AllTrails (generic green, paywall everywhere), CalTopo (powerful, ugly). Aim for the density of CalTopo with the calm of Things 3.

### 9.2 Type

Two families max. UI: Inter (system fallback fine). Numbers, coordinates, stats: JetBrains Mono (tabular figures, same as ZestSSH terminal). Never below 11 sp. Stats tiles use `displaySmall` numbers with `labelSmall` captions.

### 9.3 Color roles

| Role | Dark | Light |
|---|---|---|
| Background | `#0E1412` | `#F6F3EC` |
| Surface | `#15201B` | `#FFFFFF` |
| Surface raised | `#1E2C25` | `#FFFFFF` + 1 dp border `#E5E0D5` |
| Accent (one per surface) | `#D9A441` | `#B8862E` |
| Text primary | `#F1EEE6` | `#1B1F1D` |
| Text secondary | `#A9B0AB` | `#5B615E` |
| Fire | `#E5484D` | same |
| Smoke / caution | `#F5A524` | same |
| Water / track | `#3FB8AF` | `#2B8F88` |
| Closure / stale | `#8B8B8B` | same |

The single-accent rule from ZestSSH applies: one solid gold element per screen (usually the primary button or the active tab indicator). Everything else is outline or text.

### 9.4 Components

- Map bottom panel: `DraggableScrollableSheet` with a drag handle, min 0.12 (just the stats strip), snaps 0.4 and 0.9
- Stat tile: number in mono, caption below, no borders, 8 dp radius
- Condition badge: pill, colored dot on the left, short text, tap for detail
- Elevation profile: 140 dp, gradient by grade, scrubber line, min and max labels
- Buttons: `FilledButton` gold for the one primary action, `OutlinedButton` for secondary, `TextButton` for cancel. 48 dp min height, 48 dp touch targets everywhere
- Haptics: light on waypoint add, medium on recording start/stop and off-route, heavy on delete confirm

### 9.5 Copy rules

Short. Specific. No exclamation points. No "Oops". Errors say what happened and what to do:

- Not "Something went wrong!" but "Trail data could not load. Showing saved trails."
- Not "Enable location for the best experience" but "Turn on location to see where you are on the map."
- Not "Congrats on your hike!" but "Saved: 18.4 mi, 3,609 ft."

Fire data always includes when it was updated. Estimates say "estimate". Nothing pretends to know trail conditions it does not have.

### 9.6 Screen mockups

**Map (default)**

```
┌───────────────────────────────────────────┐
│ ▣ Topo ▾                        ◎   ⧉    │  style pill (left), compass, layers
│                                           │
│        ·  ·  Snowgrass Trail #96  ·  ·    │
│     ·           ┈┈┈┈┈┈┈ (PCT)             │
│  ▲ Old Snowy            ▒▒▒▒ Skyo Fire    │  red translucent perimeter
│         ●━━━━━━●━━━━━━━●  route (gold)    │
│           ≈ Goat Lake                     │
│                                    (◉)    │  location FAB
│═══════════════════════════════════════════│
│ ━━  Goat Rocks loop     12.4 mi  +2,706ft │  stats strip (sheet at 0.12)
│     ● Skyo Fire 6.1 mi   ● AQI 42 Good    │  condition badges
├───────────────────────────────────────────┤
│  Map     Plan     Record     Library      │
└───────────────────────────────────────────┘
```

**Trail detail sheet (0.4)**

```
│ ─                                          │
│ Snowgrass Trail                    #96 USFS│
│ Gifford Pinchot NF · Goat Rocks Wilderness │
│ ┌────────┐ ┌────────┐ ┌────────┐           │
│ │ 4.6 mi │ │ +1,900 │ │ dirt   │           │
│ │ segment│ │   ft   │ │ T2 hike│           │
│ └────────┘ └────────┘ └────────┘           │
│ ▁▂▃▅▆▇█▇▆▅  (profile of this way)          │
│ ● Free self-issue permit at trailhead      │
│ [ Plan a route from here ]  [ Show route ] │
```

**Plan**

```
┌───────────────────────────────────────────┐
│ ←  Goat Rocks loop            ⟲  ⟳   Save │
│  (map with gold route, waypoints ①②③④⑤)   │
│                                           │
│═══════════════════════════════════════════│
│ 18.4 mi   +3,609 ft   -3,590 ft   7,880 ft│
│ est. 8h 10m                    pack 45 lb │
│ ┌───────────────────────────────────────┐ │
│ │        ╱╲    ╱╲╱╲                     │ │  profile, grade gradient
│ │   ╱╲╱╲╱  ╲╱╲╱    ╲╲                   │ │
│ │ ╱╱                  ╲╲___╱╲           │ │
│ │ |         |    ▮ water   |            │ │  blue water ticks
│ └───────────────────────────────────────┘ │
│ ① Berry Patch TH    0.0 mi   4,540 ft     │
│ ② Snowgrass Flats   4.6 mi   5,900 ft   ⋮ │
│ ③ Old Snowy         7.7 mi   7,880 ft   ⋮ │
│ ④ Goat Lake        13.1 mi   6,665 ft   ⋮ │
│ ⑤ Berry Patch TH   18.4 mi   4,540 ft     │
│ Water: 0.0 Goat Creek · 4.6 Snowgrass Cr  │
│ (last before the climb) · 13.1 Goat Lake  │
└───────────────────────────────────────────┘
```

**Record (live)**

```
┌───────────────────────────────────────────┐
│  (map, teal track, gold planned route)    │
│                                  ◉  📍    │
│═══════════════════════════════════════════│
│   6.26 mi        2:58:53        26:28 /mi │
│   distance       moving         pace      │
│   1,913 ft       2.3 mph        5,480 ft  │
│   gain           speed          elevation │
│ ● On route · 12.1 mi to go · ETA 4:40 PM  │
│        [ ⏸ Pause ]      [ ■ Finish ]      │
└───────────────────────────────────────────┘
```

**Conditions panel (0.9)**

```
│ Conditions for Goat Rocks loop   updated 4m│
│ ● Skyo Fire  312 ac · 0% · 6.1 mi from route│
│   updated 12 min ago          Open InciWeb ›│
│ ● Air quality  42 Good (model)   ▁▂▂▃▂▁▁   │
│ ● Red Flag Warning until 8 PM Thu      NWS ›│
│ Weather                                     │
│   Trailhead 4,540 ft  68° · 10% · W 8 mph   │
│   High pt  7,880 ft   51° · 20% · W 22 g35  │
│ Daylight  6:24 → 7:52 (13h 28m)  ☾ 17%      │
│ Land  Gifford Pinchot NF · Stage 1 fire ban │
│       Goat Rocks Wilderness · self-issue    │
│       permit                                │
│ Parking  Berry Patch TH · NW Forest Pass or │
│          America the Beautiful              │
```

**Offline regions**

```
│ Offline maps                        + New  │
│ ┌─────────────────────────────────────────┐│
│ │ Goat Rocks        Outdoors · Topo  142MB││
│ │ z12 to z14 · trails + terrain · Aug 20  ││
│ │ [Refresh conditions]  [Delete]          ││
│ └─────────────────────────────────────────┘│
│ ┌─────────────────────────────────────────┐│
│ │ Mt Adams north     Outdoors        88MB ││
│ │ downloading 61%  ████████░░░░░           ││
│ └─────────────────────────────────────────┘│
```

---

## 10. Localization keys

`lib/l10n/app_en.arb` starter. Grow it as you go; every key documented with a description.

```json
{
  "@@locale": "en",
  "appName": "Cairn",
  "tabMap": "Map", "tabPlan": "Plan", "tabRecord": "Record", "tabLibrary": "Library",

  "styleOutdoors": "Outdoors", "styleTopo": "Topo", "styleSatellite": "Satellite",
  "layersTitle": "Layers",
  "layerTrails": "Trails", "layerPois": "Water, camps, peaks", "layerFires": "Active fires",
  "layerLand": "Wilderness and park boundaries", "layerHillshade": "Hillshade",

  "locationPermissionTitle": "Turn on location",
  "locationPermissionBody": "Turn on location to see where you are on the map.",
  "backgroundLocationBody": "Cairn records your hike with the screen off. Choose Allow all the time so the track does not stop when you lock your phone.",

  "trailUnnamed": "Unnamed path",
  "trailSegmentLength": "{distance} segment",
  "@trailSegmentLength": { "placeholders": { "distance": { "type": "String" } } },
  "trailUsfsNumber": "#{number} USFS",
  "@trailUsfsNumber": { "placeholders": { "number": { "type": "String" } } },
  "trailPlanFromHere": "Plan a route from here",
  "trailShowRoute": "Show route",
  "trailsOfflineBanner": "Trail data could not load. Showing saved trails.",

  "sacHiking": "T1 hiking", "sacMountainHiking": "T2 mountain hiking",
  "sacDemandingMountainHiking": "T3 demanding", "sacAlpineHiking": "T4 alpine",
  "sacDemandingAlpineHiking": "T5 demanding alpine", "sacDifficultAlpineHiking": "T6 difficult alpine",
  "trailInformal": "Informal path",

  "planTitle": "Plan", "planSave": "Save", "planUndo": "Undo", "planRedo": "Redo",
  "planNameHint": "Route name",
  "planOffTrail": "Off trail",
  "planEstTime": "est. {time}",
  "@planEstTime": { "placeholders": { "time": { "type": "String" } } },
  "planPackWeight": "pack {weight}",
  "@planPackWeight": { "placeholders": { "weight": { "type": "String" } } },
  "planWaterHeader": "Water",
  "planWaterLastBeforeClimb": "last before the climb",
  "planWaterSeasonal": "Seasonal streams may be dry in late summer.",

  "statDistance": "distance", "statGain": "gain", "statLoss": "loss", "statHighPoint": "high point",
  "statMoving": "moving", "statPace": "pace", "statSpeed": "speed", "statElevation": "elevation",
  "statTotalTime": "total",

  "recordStart": "Start", "recordPause": "Pause", "recordResume": "Resume", "recordFinish": "Finish",
  "recordDiscard": "Discard", "recordSavedSummary": "Saved: {distance}, {gain}.",
  "@recordSavedSummary": { "placeholders": { "distance": { "type": "String" }, "gain": { "type": "String" } } },
  "recordNotificationTitle": "Recording",
  "recordNotificationBody": "{distance}, {time}",
  "@recordNotificationBody": { "placeholders": { "distance": { "type": "String" }, "time": { "type": "String" } } },
  "recordOnRoute": "On route", "recordOffRoute": "Off route",
  "recordToGo": "{distance} to go",
  "@recordToGo": { "placeholders": { "distance": { "type": "String" } } },
  "recordEta": "ETA {time}",
  "@recordEta": { "placeholders": { "time": { "type": "String" } } },
  "recordAutoPaused": "Auto-paused",

  "libraryRoutes": "Routes", "libraryTracks": "Tracks", "libraryOffline": "Offline",
  "libraryEmptyRoutes": "No saved routes. Plan one from the map.",
  "libraryEmptyTracks": "No recordings yet.",
  "libraryDelete": "Delete", "libraryUndo": "Undo",

  "gpxImport": "Import GPX", "gpxExport": "Export GPX",
  "gpxImportFailed": "That file could not be read as GPX.",

  "offlineTitle": "Offline maps", "offlineNew": "New region",
  "offlineEstimate": "about {size}",
  "@offlineEstimate": { "placeholders": { "size": { "type": "String" } } },
  "offlineLargeWarning": "This region is over 1 GB. Lower the max zoom or shrink the area.",
  "offlineDownloading": "downloading {percent}%",
  "@offlineDownloading": { "placeholders": { "percent": { "type": "int" } } },
  "offlineIncomplete": "Incomplete", "offlineResume": "Resume",
  "offlineRefresh": "Refresh conditions",

  "condTitle": "Conditions for {name}",
  "@condTitle": { "placeholders": { "name": { "type": "String" } } },
  "condUpdatedAgo": "updated {ago}",
  "@condUpdatedAgo": { "placeholders": { "ago": { "type": "String" } } },
  "condStale": "stale",
  "condFireCrosses": "Route crosses the {name} perimeter",
  "@condFireCrosses": { "placeholders": { "name": { "type": "String" } } },
  "condFireDistance": "{name} is {distance} from the route",
  "@condFireDistance": { "placeholders": { "name": { "type": "String" }, "distance": { "type": "String" } } },
  "condFireNone": "No active fires within 50 mi",
  "condFireAcres": "{acres} ac", "condFireContained": "{percent}% contained",
  "@condFireAcres": { "placeholders": { "acres": { "type": "String" } } },
  "@condFireContained": { "placeholders": { "percent": { "type": "int" } } },
  "condOpenInciweb": "Open on InciWeb",
  "condAqi": "Air quality", "condAqiModel": "Model estimate. Monitor data in a later update.",
  "condAqiMonitor": "EPA AirNow monitor",
  "aqiGood": "Good", "aqiModerate": "Moderate", "aqiUsg": "Unhealthy for sensitive groups",
  "aqiUnhealthy": "Unhealthy", "aqiVeryUnhealthy": "Very unhealthy", "aqiHazardous": "Hazardous",
  "condWeather": "Weather", "condTrailhead": "Trailhead", "condHighPoint": "High point",
  "condDaylight": "Daylight", "condMoon": "moon {percent}% {phase}",
  "@condMoon": { "placeholders": { "percent": { "type": "int" }, "phase": { "type": "String" } } },
  "moonNew": "new", "moonWaxingCrescent": "waxing crescent", "moonFirstQuarter": "first quarter",
  "moonWaxingGibbous": "waxing gibbous", "moonFull": "full", "moonWaningGibbous": "waning gibbous",
  "moonLastQuarter": "last quarter", "moonWaningCrescent": "waning crescent",
  "condLand": "Land", "condParking": "Parking",
  "condWildernessPermit": "Free self-issue permit at the trailhead",
  "condNpsFee": "Park entrance fee or America the Beautiful pass",
  "condNwForestPass": "Northwest Forest Pass or America the Beautiful",
  "condDiscoverPass": "Discover Pass",
  "condRestrictionStage": "Stage {stage} fire restrictions",
  "@condRestrictionStage": { "placeholders": { "stage": { "type": "int" } } },

  "settingsTitle": "Settings", "settingsUnits": "Units", "unitsImperial": "Miles, feet, °F",
  "unitsMetric": "Kilometers, meters, °C", "settingsTheme": "Theme", "themeSystem": "System",
  "themeDark": "Dark", "themeLight": "Light", "settingsDefaultStyle": "Default map",
  "settingsBodyWeight": "Body weight (for calorie estimates)", "settingsPackWeight": "Default pack weight",
  "settingsTerrainCache": "Terrain cache", "settingsClearCache": "Clear",
  "settingsSources": "Data sources and attribution", "settingsPrivacy": "Privacy",
  "settingsLicenses": "Open source licenses", "settingsVersion": "Version {version}",
  "@settingsVersion": { "placeholders": { "version": { "type": "String" } } },

  "summitTitle": "Cairn Summit", "summitOneTime": "One-time purchase. No subscription.",
  "summitRestore": "Restore purchase",
  "summitFeatureOffline": "Unlimited offline regions",
  "summitFeatureWater": "Water and campsite planning",
  "summitFeatureFollow": "Follow a route while recording",
  "summitFeatureAirnow": "EPA monitor air quality",

  "attributionOsm": "© OpenStreetMap contributors",
  "attributionOpenFreeMap": "© OpenFreeMap © OpenMapTiles",
  "attributionUsgs": "USGS The National Map",
  "attributionTerrain": "Terrain: Mapzen / AWS Terrain Tiles",
  "attributionNifc": "Fire data: NIFC WFIGS",
  "attributionNws": "Weather: NOAA National Weather Service",
  "attributionOpenMeteo": "Air quality: Open-Meteo",

  "genericRetry": "Retry", "genericCancel": "Cancel", "genericOk": "OK", "genericSave": "Save"
}
```

Every stat and distance string goes through `UnitFormatter` so "18.4 mi" and "29.6 km" come from the same call.

---

## 11. Android manifest essentials

`android/app/src/main/AndroidManifest.xml` (relevant parts):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

  <application
      android:label="@string/app_name"
      android:icon="@mipmap/ic_launcher"
      android:allowBackup="false"
      android:usesCleartextTraffic="false"
      android:networkSecurityConfig="@xml/network_security_config">

    <service
        android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
        android:foregroundServiceType="location"
        android:exported="false"/>

    <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop"
        android:theme="@style/LaunchTheme">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
      <!-- Open .gpx from downloads, email, browser -->
      <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="content" android:mimeType="application/gpx+xml"/>
        <data android:scheme="content" android:mimeType="application/octet-stream" android:pathPattern=".*\\.gpx"/>
        <data android:scheme="file" android:pathPattern=".*\\.gpx"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
```

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<network-security-config>
  <base-config cleartextTrafficPermitted="false"/>
</network-security-config>
```

`minSdkVersion 26`, `targetSdkVersion` = current Play requirement (35 at time of writing; check).

---

## 12. Open source model, licensing, and the two builds

Cairn is open source. The source is the product; the store build is a convenience. This is the OsmAnd model: full source on GitHub, a free build on the store with a one-time unlock, and a fully unlocked build anyone can compile or grab from F-Droid. People who pay are buying convenience and supporting the project, not access to hidden code.

### 12.1 Licenses

- App (`cairn/`): **GPL-3.0-or-later**. `LICENSE` at the repo root, SPDX header on every Dart file: `// SPDX-License-Identifier: GPL-3.0-or-later`.
- Proxy (`cairn-proxy/`, Phase 8): **AGPL-3.0-or-later**, its own repo.
- Assets you draw (icons, sprite): CC-BY-SA 4.0, stated in `assets/LICENSE`.
- Bundled data (`assets/data/*.json`): CC0 where you wrote it; carry the upstream license where you did not.
- Copyright holder on all of it: Affluent Labs. Being the sole copyright holder is what lets you grant an App Store exception later (Apple's terms and GPL conflict; the standard fix is an additional permission clause from the copyright holder, add it in Phase 11 when iOS starts).
- `CONTRIBUTING.md` asks contributors to agree that their contributions are licensed under the same GPL-3.0-or-later. No CLA, no copyright assignment. Keep it simple.

### 12.2 Dependency rule (replaces the closed-source rule)

Any license compatible with GPL-3 is fine: MIT, BSD, Apache-2.0, MPL-2.0, LGPL, GPL-2.0-or-later, GPL-3. Not fine: proprietary SDKs that forbid redistribution of source, and GPL-2.0-only. `purchases_flutter` (RevenueCat) is MIT and only ships in the store flavor, so it is fine. This reopens `flutter_map_tile_caching` (GPL-3) as an option if MapLibre ever becomes a problem, but the engine decision in Section 4 stands.

Run `flutter pub deps --json` in Phase 9 and write every direct dependency's license into `docs/LICENSES.md`. `showLicensePage` covers the in-app requirement.

### 12.3 Two builds, one flag

Android product flavors in `android/app/build.gradle.kts`:

```kotlin
android {
    flavorDimensions += "distribution"
    productFlavors {
        create("community") {
            dimension = "distribution"
            applicationIdSuffix = ""          // same id so users can switch builds without losing data
            buildConfigField("boolean", "STORE_BUILD", "false")
        }
        create("store") {
            dimension = "distribution"
            buildConfigField("boolean", "STORE_BUILD", "true")
        }
    }
}
```

On the Dart side use `--dart-define=CAIRN_STORE=true` rather than reading BuildConfig, so the same switch works on iOS later:

`lib/features_flags.dart`:

```dart
/// True only in the Play Store / App Store build. Community builds (GitHub Releases,
/// F-Droid, self-compiled) are always fully unlocked.
const bool kStoreBuild = bool.fromEnvironment('CAIRN_STORE', defaultValue: false);

/// Everything Cairn Summit unlocks in the store build. Community build returns true.
abstract final class Summit {
  static bool has(Ref ref) => !kStoreBuild || ref.watch(entitlementProvider).hasSummit;
}
```

Build commands (put them in `tool/build.sh`):

```bash
# Community build: fully unlocked, no RevenueCat, no Google services
flutter build apk --release --flavor community --obfuscate --split-debug-info=debug-symbols/$V

# Store build: Summit gate on, RevenueCat wired
flutter build appbundle --release --flavor store --dart-define=CAIRN_STORE=true \
  --obfuscate --split-debug-info=debug-symbols/$V
```

The community flavor must not link `purchases_flutter` or any Google Play services at all. Do this with a conditional import: `lib/data/purchases/purchases.dart` exports either `purchases_store.dart` (real RevenueCat) or `purchases_noop.dart` (always entitled) based on `kStoreBuild`. F-Droid will reject a build that contains proprietary Google libraries, and their scanner checks the binary, not your intentions.

### 12.4 What Summit gates (store build only)

- Unlimited offline regions (community and free-store users get one region, 500 MB)
- Water and campsite planning helpers (Phase 8)
- Follow-route mode while recording
- EPA AirNow monitor air quality (the model AQI stays free)

Never gated in any build: map, trails, planner, elevation, one offline region, recording, GPX import and export, fires, weather, NWS alerts, daylight and moon. Safety information is never behind a purchase.

RevenueCat via `purchases_flutter`, product id `cairn_summit_lifetime`, USD 9.99. Google sign-in only for restore, no Cairn account. Debug builds of either flavor are fully unlocked.

### 12.5 F-Droid and GitHub Releases

- Tag releases `v0.1.0`. A GitHub Action builds the community APK, signs it with the community keystore (separate from the Play keystore, both gitignored, both in the user's password manager), attaches it to the release with a SHA-256.
- F-Droid metadata lives in `metadata/en-US/` (short and full description, changelogs, screenshots). Submit to F-Droid after the first tagged release with a working reproducible build. Their build server compiles from source, so the community flavor must build with nothing but the Flutter SDK and public pub packages.
- The community and store builds share the same `applicationId` so a user can move between them; the Drift database and terrain cache carry over. Note this in the README so people know not to install both at once.

### 12.6 README and repo hygiene (Phase 0 deliverable, public from the first commit)

- `README.md`: what it is, screenshots (add in Phase 7), install links (Play, F-Droid, GitHub), the two-build explanation in three sentences, data sources with attribution, how to build, license.
- `CONTRIBUTING.md`: house rules from `CLAUDE.md` in human form, plus "open an issue before a big PR".
- `SECURITY.md`: how to report a vulnerability (email), no bug bounty.
- `.github/ISSUE_TEMPLATE/`: bug, feature, data correction (wrong trail name, missing water source, which should point people at OpenStreetMap edits, not Cairn).
- Never commit: keystores, `debug-symbols/`, `.env`, the proxy's keys.

Build every feature ungated first. The gate is a single `Summit.has(ref)` check at the four gated entry points, added in Phase 9.

---

## 13. Q&A: decisions already made so you never stop

| Question | Answer |
|---|---|
| App name and ids? | Cairn, `com.affluentlabs.cairn`. Rename is trivial later. |
| Flutter or native? | Flutter. Same as the other Affluent Labs apps. |
| Map engine? | `maplibre_gl`. Reason in Section 4. |
| State management? | Riverpod with code generation. |
| Database? | Drift. Same as the other apps. |
| Which basemap is default? | Outdoors (OpenFreeMap vector + hillshade). Topo is one tap away. |
| Min Android version? | API 26. |
| iOS? | Not in scope until Phase 11. Keep code platform-clean but do not test on iOS. |
| Units? | Imperial default, metric toggle, SI internally. |
| Time format? | Follow device 12/24 h setting. |
| Where do keys go? | Nowhere in the app. Proxy in Phase 8. Until then, use only the no-key sources. |
| Overpass is slow or down? | Try the two mirrors, then show cached data with a banner. Never block the map. |
| A field name in an API differs from this doc? | Use the live field, note it in `docs/API_NOTES.md`. |
| A package in Section 4 is deprecated or fails to build? | Pick the closest maintained alternative, note it in `docs/DECISIONS.md`, keep going. Do not spend more than 30 minutes fighting a build. |
| Elevation source for gain: GPS or DEM? | DEM always when available. GPS altitude is a fallback only. |
| How accurate must route stats be? | Distance within 5%, gain within 10% of CalTopo for the same line. |
| Contour lines? | Provided by the USGS Topo raster style. Do not generate contours in v1. |
| Sprite icons? | 10 simple monochrome SVGs, generated sprite. If sprite tooling is painful, `controller.addImage` at runtime from PNGs in assets. |
| Fires older than what to hide? | Trust NIFC's fall-off rules; do not filter further. Show the update timestamp. |
| Trail "difficulty" rating like AllTrails? | No. Show SAC scale, gain per mile, and max grade. Let the user judge. |
| Photos? | Not in v1. |
| Search? | Phase 2 gets a name search over cached ways and relations (Drift `LIKE`). Place search (towns, trailheads) via Nominatim `https://nominatim.openstreetmap.org/search?q=&format=json&limit=5` with the User-Agent header, 1 request per second max. |
| Testing device? | Physical Android phone. Emulator for unit tests only; MapLibre and background location misbehave on emulators. |
| What if the user is silent for days? | Keep going through Phase 9. Stop before Phase 10. |
| Commit style? | `phase-N: summary`. Conventional commits inside a phase are fine. |
| Licensing of the app? | Open source, GPL-3.0-or-later. Proxy is AGPL-3.0-or-later. Dependencies must be GPL-3 compatible (MIT, BSD, Apache-2.0, MPL, LGPL, GPL). Write every direct dependency's license into `docs/LICENSES.md` in Phase 9. |
| Is the repo public from the start? | Yes. First commit is public. Never commit keystores, `debug-symbols/`, `.env`, or proxy keys. |
| Which build am I working in day to day? | The community flavor. It is the default and has no store code paths. Only touch the store flavor in Phase 9. |
| Does the community build have to avoid Google libraries? | Yes, for F-Droid. No `purchases_flutter`, no Play services, no Firebase in the community flavor. Conditional import in `lib/data/purchases/purchases.dart`. |
| Which features does Summit gate? | Only the four in Section 12.4. Fires, weather, alerts, one offline region, recording, GPX are never gated in any build. |
| Someone opens a PR? | Not your problem during the build. The user reviews PRs. Keep `CONTRIBUTING.md` accurate so they can. |
| SPDX headers? | `// SPDX-License-Identifier: GPL-3.0-or-later` on every Dart file. Add a lint script `tool/check_spdx.sh` that fails CI if one is missing. |

---

## 14. Verification and test plan

**Unit tests (must exist before Phase 3 ends):**
- `tile_math_test.dart`: 20 random coordinates round-trip through tile and pixel math within 1e-7 degrees
- `haversine_test.dart`: Tacoma to Seattle 40.6 km ± 0.1%
- `terrarium_test.dart`: fixture tile pixel (128,128) decodes to the known value
- `elevation_stats_test.dart`: sawtooth [0,10,0,10,0] with threshold 5 gives gain 20 loss 20; noise [0,2,0,2,0] gives 0
- `dijkstra_test.dart`: 5-node fixture, known path
- `solar_test.dart`: Tacoma 2026-09-10 sunrise 06:38, sunset 19:26 PDT within 2 min (verify against timeanddate before pinning)
- `moon_test.dart`: 2026-07-25 illumination matches a reference within 3 points
- `aqi_test.dart`: 0, 50, 51, 100, 101, 150, 151, 200, 201, 300, 301 map to the right category
- `overpass_parse_test.dart`: fixture parses; a known way id has the expected node count

**Device checklist (manual, per phase, recorded in `docs/PROGRESS.md` with screenshots in `docs/screens/`):** listed under each phase's acceptance section.

**Performance budget:** cold start to interactive map under 2.5 s on a mid-range device; viewport trail update under 250 ms warm; memory under 350 MB with a 20 mile route and profile open.

---

## 15. CLAUDE.md (put this at the repo root verbatim)

```markdown
# Cairn: rules for Claude Code

- Read docs/cairn-build-spec.md first. Work phases in order. Update docs/PROGRESS.md after each phase.
- This repo is public and GPL-3.0-or-later. SPDX header on every Dart file. Never commit keystores, debug-symbols/, .env, or keys.
- Two flavors: community (default, fully unlocked, no Google libraries) and store (Summit gate via --dart-define=CAIRN_STORE=true). Work in community. Touch store only in Phase 9.
- Flutter + Dart. Riverpod (generated). Drift. maplibre_gl. go_router. Dio.
- Every user-visible string is an l10n key in lib/l10n/app_en.arb. No exceptions.
- No em dashes anywhere. Not in code, comments, strings, docs, or commits.
- No analytics, ads, crash SDKs, or third-party tracking.
- No API keys in the app. Keyed sources go through the Affluent Labs proxy (Phase 8).
- All network calls HTTPS. User-Agent "Cairn/<version> (contact@affluentlabs.dev)" on every request.
- Units: SI internally, format at the edge via UnitFormatter.
- Elevation gain uses DEM with 5 m hysteresis. Never raw GPS altitude deltas.
- flutter analyze must be clean and flutter test must pass before every commit.
- Commit message format: phase-N: what shipped.
- Decisions made without the user go in docs/DECISIONS.md with a one-line reason.
- If an API's real field names differ from the spec, trust the API and log it in docs/API_NOTES.md.
- Do not start Phase 10 or later without the user.
```

---

## 16. First hour, in order

1. `git init`, add `LICENSE` (GPL-3.0-or-later text from gnu.org), `.gitignore` (Flutter template plus `*.jks`, `*.keystore`, `debug-symbols/`, `.env`, `key.properties`). First commit is just these.
2. `flutter create --org com.affluentlabs --project-name cairn --platforms android .`
3. Add dependencies from Section 4. `flutter pub get`.
4. Add the `community` and `store` flavors from Section 12.3 to `android/app/build.gradle.kts`. Create `lib/data/purchases/purchases.dart` with the conditional import and the no-op implementation.
5. Create the folder tree from Section 6 with placeholder files, each with the SPDX header. Write `tool/check_spdx.sh`.
6. Write `l10n.yaml`, `analysis_options.yaml`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `docs/*.md`, `.github/ISSUE_TEMPLATE/*.md`.
7. Write `.github/workflows/ci.yml`: on push run `flutter analyze`, `flutter test`, `tool/check_spdx.sh`; on tag `v*` build the community APK and attach it to a GitHub Release with a SHA-256.
8. Implement Phase 0. Run on device. Commit.
9. Run `tool/fetch_styles.dart` to snapshot the OpenFreeMap style into `assets/map_styles/outdoors.json`, then hand-append the terrain source, hillshade layer, and `cairn-*` sources and layers from Section 8 Phase 1.
10. Implement Phase 1. Run on device. Commit.
11. Capture real API responses into `test/fixtures/` (Overpass for the Goat Rocks bbox 46.40,-121.55,46.55,-121.35; NIFC for Washington; NWS points for 46.4623,-121.4512; one terrarium tile) so tests never hit the network.
12. Continue through the phases.

That is the whole plan. Build it.
