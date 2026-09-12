<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# API notes: real field names discovered at runtime

The spec was researched on 2026-09-10. When a live API returns something different, the
truth goes here and the code adapts. Format: source, endpoint, what differed, date.

## To verify on a device with network (NEEDS DEVICE / NETWORK)

These were coded to the spec's documented field names. Confirm against a live response and
update the parser plus this note if they differ:

- **Overpass** (`overpass-api.de/api/interpreter`): element shape `{type, id, nodes, tags,
  lat, lon}`. Coded in `lib/data/sources/overpass_source.dart`.
- **USFS EDW** trails / wilderness / forests ArcGIS layers: field names vary per layer. Hit
  `{base}?f=json` and record the field list. Trail name and number fields are guessed as
  `TRAIL_NAME` / `TRAIL_NO`; wilderness name as `NAME`; forest name as `FORESTNAME`. Coded in
  `lib/data/sources/usfs_source.dart` with a tolerant field lookup.
- **NWS** (`api.weather.gov`): `/points/{lat},{lon}` gives `properties.forecast*`. Requires a
  User-Agent. Coded in `lib/data/sources/nws_source.dart`.
- **Open-Meteo**: air quality `hourly.us_aqi`, `hourly.pm2_5`; forecast `hourly.*`. Coded in
  `lib/data/sources/open_meteo_source.dart`.
- **NPS boundary** and **WA State Parks** ArcGIS layers (Phase 7 and 8): confirm the layer
  index and field names live before relying on them.

## Verified

- **NIFC WFIGS** (2026-09-11, live `?f=pjson` field lists and one record from each layer).
  The **incident locations** layer (`WFIGS_Incident_Locations_Current/FeatureServer/0`) has
  plain IRWIN field names, not the `attr_` prefix the spec assumed: `IncidentName`,
  `IncidentSize`, `DiscoveryAcres`, `FinalAcres`, `PercentContained`, `FireDiscoveryDateTime`
  (epoch ms), `ModifiedOnDateTime_dt` (epoch ms), `IncidentTypeCategory` (`WF` / `RX`),
  `FireBehaviorGeneral`, `POOProtectingUnit` ("WAOLP"), `POOState` ("US-WA"), `IrwinID`
  ("{7A43...}"), `UniqueFireIdentifier` ("2026-WAOLP-000147"). The **perimeters** layer
  (`WFIGS_Interagency_Perimeters_Current/FeatureServer/0`) prefixes its polygon fields with
  `poly_` (`poly_IncidentName`, `poly_GISAcres`, `poly_DateCurrent`, `poly_IRWINID`) and the
  same IRWIN attributes with `attr_` (`attr_IncidentName`, `attr_PercentContained`, ...). The
  two names can differ for one fire (`poly_IncidentName` "Mt Toms Creek" vs `attr_IncidentName`
  "Mount Tom Creek"), so points are deduplicated against perimeters by IRWIN id first and the
  `attr_` name is preferred. Until this check the incident points parsed only the `attr_`
  spellings, so acres, containment, dates and prescribed-burn status were missing for every
  fire without a perimeter. Fixtures in `test/fixtures/wfigs_*.json` mirror both shapes.
- **NWS** (2026-09-11, live). `/points/46.47,-121.46` returns `properties.forecastHourly`
  (`/gridpoints/SEW/142,10/forecast/hourly`); the hourly periods carry `startTime`,
  `temperature` + `temperatureUnit` ("F"), `probabilityOfPrecipitation.value`, `windSpeed`
  ("2 mph" or "5 to 10 mph"), `windGust`, `shortForecast`, as coded. Alerts use
  `properties.event`, `severity`, `ends`. Fixtures in `test/fixtures/nws_*.json`.
- **InciWeb** has no JSON API, as the spec says, but `https://inciweb.wildfire.gov/incidents/rss.xml`
  lists every current incident as `<item><title>UNIT Name</title><link>...</link>` (for example
  "WAOLP Mount Tom Creek Fire" and
  `http://inciweb.wildfire.gov/incident-information/waolp-mount-tom-creek-fire`). "Open on
  InciWeb" fetches the feed on demand (kept an hour), matches the WFIGS incident by normalized
  name with `POOProtectingUnit` as the tie-breaker, and opens the incident page; the home page
  is the fallback. Coded in `lib/data/sources/inciweb_source.dart`.
- **Nominatim** usage policy (operations.osmfoundation.org/policies/nominatim, 2026-09-11): at
  most one request per second, an identifying User-Agent, no autocomplete, cache repeats. The
  place search runs on submit only, throttles to 1 req/s and caches the last 30 queries
  (`lib/data/sources/nominatim_source.dart`). Response shape (`format=jsonv2`): `lat`, `lon`,
  `name`, `display_name`, `type`, `boundingbox` [south, north, west, east] as strings.
- **Solar times** (`lib/core/geo/solar.dart`): verified against api.sunrise-sunset.org
  (NOAA algorithm) for Tacoma 2026-09-10. Ours matches to within ~30 seconds (sunrise
  13:39:44Z ref vs 13:40:14Z ours; sunset 02:33:31Z ref vs 02:33:41Z ours). The spec's
  Section 14 figure "sunset 19:26 PDT" was rough; the real value is ~19:33 PDT and the test
  is pinned to the verified reference, not the spec figure.
- **Moon** (`lib/core/geo/moon.dart`): mean synodic-cycle method (Meeus, simplified). Anchor
  cases (new, full, quarter) are exact by construction. The 2026-07-25 pin (~82 percent,
  waxing gibbous) should still be cross-checked against a live reference to trust the last
  percentage point.

## Phase R

- 2026-09-11: Addendum A5.1 specified building the `terrain.json` and `road.json` base
  styles from fetched OpenFreeMap `positron` and `bright` style snapshots. No reliable
  network fetch was available in this session, so both were derived instead from the
  existing `outdoors.json` (OpenFreeMap liberty vector base plus terrain-dem hillshade plus
  the cairn-* overlay layers). `terrain.json` raises hillshade exaggeration to 0.6 and tones
  roads and labels down so relief dominates; `road.json` drops the hillshade layer and keeps
  roads and labels at normal prominence. Both keep every cairn-* source and layer. If a
  positron or bright snapshot is preferred later, regenerate these two files from it and
  preserve the same cairn-* sources and layers.
- 2026-09-11: **Overlay raster tiles (A5.3), on the Pixel_3a API 36 emulator.** Confirmed that
  MapLibre Native does not substitute the `{bbox-epsg-3857}` token in a raster source's tile
  URL, so the ArcGIS `export`/`exportImage` overlays were blank when added directly. Fixed with
  the localhost tile proxy (`tile_proxy.dart`): a `127.0.0.1` `HttpServer` turns `{z}/{x}/{y}`
  into a Web Mercator bbox, fills the token in the upstream URL, and forwards the request; the
  overlay controller routes any `{bbox-epsg-3857}` overlay through it. The **slope-angle**
  overlay (USGS 3DEP Slope Map) now renders correctly through the proxy (verified at z13 over
  Goat Rocks). The other 3DEP overlay (lidar hillshade) uses the same shape. The NWS weather
  overlays go through the same proxy, and their service paths were verified live and corrected
  in `overlay_registry.dart`: radar `eventdriven/.../radar/radar_base_reflectivity/MapServer`
  (correct as written; it is transparent on a clear day, which is normal, not a bug);
  temperature `raster/.../NDFD/NDFD_temp/MapServer` layer 5 (`Temp_00Hr`, current temperature)
  (the folder is capital `NDFD`, not `ndfd`); snow depth
  `raster/.../snow/NOHRSC_Snow_Analysis/MapServer` layer 0 (`Snow Depth`, was wrongly layer 3).
  Lidar hillshade uses the 3DEP ImageServer like slope, which is verified rendering. OSM GPS
  traces (`gps.tile.openstreetmap.org`, standard XYZ) installs directly (no proxy) and is just
  sparse in this area.
