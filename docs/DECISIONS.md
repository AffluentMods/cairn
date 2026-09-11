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
- **Follow-route Summit gate pending the user's decision.** Reason: Section 12.4 gates follow
  mode behind Summit, but Navigate's Start uses follow mode. Built ungated for now (gates land
  in Phase 9 regardless); open item in PROGRESS: is follow-route free?
- **FavoriteTrails and UserWaypoints land in Drift schema v3, not v2.** Reason: Addendum A7
  wrote them as v2, but the sync feature had already claimed schemaVersion 2 (Tombstones +
  Tracks.lastModified). Trust the real code: these two tables ship in a v2 to v3 migration so
  no existing install loses data. Tables are defined inline in `app_database.dart` to match the
  existing convention there, not as separate files under `db/tables/`.
