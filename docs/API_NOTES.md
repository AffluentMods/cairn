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
- **NIFC WFIGS** perimeters: `poly_IncidentName`, `poly_GISAcres`, `attr_PercentContained`,
  `attr_FireDiscoveryDateTime`, `attr_IncidentTypeCategory`, `attr_FireBehaviorGeneral`,
  `attr_ModifiedOnDateTime_dt`. Incident points use `attr_` without the `poly_` prefix. Coded
  in `lib/data/sources/nifc_source.dart` with a tolerant field lookup that tries both.
- **NWS** (`api.weather.gov`): `/points/{lat},{lon}` gives `properties.forecast*`. Requires a
  User-Agent. Coded in `lib/data/sources/nws_source.dart`.
- **Open-Meteo**: air quality `hourly.us_aqi`, `hourly.pm2_5`; forecast `hourly.*`. Coded in
  `lib/data/sources/open_meteo_source.dart`.
- **NPS boundary** and **WA State Parks** ArcGIS layers (Phase 7 and 8): confirm the layer
  index and field names live before relying on them.

## Verified

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
