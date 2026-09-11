<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Cairn privacy

Short version: Cairn has no account, no analytics, no ads, and no third-party tracking. Your
location and your hikes stay on your device.

## What stays on your device

- Your saved routes, recorded tracks, offline map regions, trail cache, and settings live in
  a database on your phone. Cairn never uploads them anywhere unless you turn on sync, which
  is off by default.
- Location is used to show where you are on the map and to record a hike. It is not sent to
  anyone.

## What leaves your device, and only this

Cairn is a map, so it fetches map and conditions data. Each request sends only a coordinate
or a rectangular map area, never an identifier, to these public sources:

- OpenFreeMap and OpenMapTiles (basemap), USGS The National Map (topo, imagery),
  Mapzen / AWS Terrain Tiles (elevation), OpenStreetMap via Overpass (trails and points),
  USFS EDW (official trails and boundaries), NIFC WFIGS (fires), NOAA National Weather
  Service (weather), Open-Meteo (air quality and fallback weather).
- The optional Affluent Labs proxy, for the few sources that need an API key (air quality
  monitors, park alerts, campgrounds). The proxy holds the keys, not the app, and logs
  nothing but a per-address rate-limit counter.

Requests carry a User-Agent of `Cairn/<version> (contact@affluentlabs.dev)` because some of
these services require one. That string identifies the app, not you.

## Optional multi-device sync

If you turn on sync, your routes and tracks are encrypted on your device with a key derived
from a passphrase you choose (Argon2id, then AES-256-GCM) before anything leaves the phone.
The sync server, whether ours or one you self-host, only ever stores an encrypted blob it
cannot read. It never sees your passphrase, your key, or your data. Sync uses a random sync
id as its only identifier; there is still no account, no email, and no password stored on a
server in readable form.

## Permissions

Location (for the puck and recordings), background location (only requested when you start a
recording, so the track continues with the screen off), notifications (for the recording
notification), and internet. Nothing else.

## Your data is yours

Export any route or track as a GPX file at any time. Deleting the app deletes the on-device
data. If you used sync, purge it from the sync screen.

Questions: privacy@affluentlabs.dev.
