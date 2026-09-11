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

## Status at handoff

Phases 0 through 9 are code-complete, plus the multi-device sync you asked for (client and
an accountless E2E server), both API backends, a security audit, and a design mockup canvas.
`flutter analyze` is clean, 115 tests pass, both flavors build a debug APK. Everything is
committed locally on branch `main`; nothing has been pushed to a remote (see Q9).

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
