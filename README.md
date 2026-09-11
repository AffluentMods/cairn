<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Cairn

Offline-first trail maps with fire, smoke, and closure overlays, for Washington hikers.

Cairn shows what a general hiking app will not: active fire perimeters, smoke and air
quality, closures, water sources, and permit boundaries, drawn on top of USGS topo and
OpenStreetMap trails. It works with airplane mode on. No account. No subscription for the
core app.

> Status: in active development. Phase 0 to 9 per [docs/cairn-build-spec.md](docs/cairn-build-spec.md).
> Not yet published. Screenshots land at Phase 7.

## What it does

- Browse trails on USGS Topo, satellite, or an outdoors vector basemap, all with hillshade.
- Plan a route: tap waypoints, snap to trails, get distance, elevation gain, and an
  elevation profile with grade coloring.
- Record a hike with the screen off: distance, moving time, pace, gain, pack-aware calories.
- See conditions: NIFC fire perimeters, air quality, NWS weather at the trailhead and the
  high point, red flag warnings, daylight and moon.
- Download regions for fully offline use: tiles, terrain, trails, and land boundaries.
- Import and export GPX.
- Optional end-to-end encrypted multi-device sync (bring your own server, or self-host the
  Cairn sync server). Nothing leaves your device readable, and sync is off by default.

## Two builds, one codebase

Cairn is open source. The source is the product; the store build is a convenience.

- **Community build** (GitHub Releases, F-Droid, or compile it yourself): every feature
  unlocked, no Google Play libraries, no tracking.
- **Store build** (Google Play): identical code with a one-time "Cairn Summit" unlock (USD
  9.99) for convenience features. Safety information is never behind a purchase.

Both builds share the same application id, so you can move between them without losing your
data. Do not install both at once.

## Build

Requires the Flutter SDK (3.6+). Android only for now.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run --flavor community
```

Release artifacts are produced by [tool/build.sh](tool/build.sh).

## Data sources and attribution

Cairn renders data from OpenStreetMap (ODbL), OpenFreeMap and OpenMapTiles, USGS The
National Map (public domain), Mapzen / AWS Terrain Tiles, NIFC WFIGS fire data (CC-BY),
NOAA National Weather Service, and Open-Meteo. Full attribution is shown in the map's
attribution control and in Settings, Data sources.

To fix a wrong trail name or a missing water source, edit
[OpenStreetMap](https://www.openstreetmap.org). Cairn re-reads OSM, so your fix reaches
every user.

## License

App: GPL-3.0-or-later. The optional sync server and proxy: AGPL-3.0-or-later. Icons and
sprite: CC-BY-SA 4.0. See [LICENSE](LICENSE) and [assets/LICENSE](assets/LICENSE).

Copyright Affluent Labs.
