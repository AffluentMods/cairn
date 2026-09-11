<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Dependency licenses

Cairn is GPL-3.0-or-later. Every direct dependency must be GPL-3 compatible: MIT, BSD,
Apache-2.0, MPL-2.0, LGPL, GPL-2.0-or-later, or GPL-3. This list is maintained by hand; run
`flutter pub deps --json` and a license scanner before a store submission to confirm, and
`showLicensePage` in the app shows the full texts to users.

## Direct dependencies (app)

| Package | Version | License | GPL-3 compatible |
|---|---|---|---|
| flutter, flutter_localizations | SDK | BSD-3-Clause | yes |
| intl | 0.20.x | BSD-3-Clause | yes |
| flutter_riverpod | 2.6.x | MIT | yes |
| riverpod_annotation | 2.6.x | MIT | yes |
| go_router | 14.x | BSD-3-Clause | yes |
| maplibre_gl | 0.22.0 | BSD-3-Clause / MIT | yes |
| drift | 2.28.x | MIT | yes |
| sqlite3_flutter_libs | 0.5.x | MIT (bundles SQLite, public domain) | yes |
| path_provider | 2.1.x | BSD-3-Clause | yes |
| path | 1.9.x | BSD-3-Clause | yes |
| shared_preferences | 2.3.x | BSD-3-Clause | yes |
| flutter_secure_storage | 9.2.x | BSD-3-Clause | yes |
| dio | 5.7.x | MIT | yes |
| latlong2 | 0.9.x | Apache-2.0 | yes |
| turf | 0.0.x | MIT | yes |
| gpx | 2.3.x | MIT | yes |
| image | 4.x | MIT | yes |
| geolocator | 13.x | MIT | yes |
| flutter_foreground_task | 8.17.x | MIT | yes |
| permission_handler | 11.x | MIT | yes |
| cryptography | 2.7.x | Apache-2.0 / MIT | yes |
| freezed_annotation | 2.4.x | MIT | yes |
| json_annotation | 4.9.x | BSD-3-Clause | yes |
| share_plus | 10.x | BSD-3-Clause | yes |
| file_picker | 8.x | MIT | yes |
| url_launcher | 6.3.x | BSD-3-Clause | yes |
| collection | 1.19.x | BSD-3-Clause | yes |
| uuid | 4.x | MIT | yes |

## Deliberately not linked in the community flavor

`purchases_flutter` (RevenueCat, MIT) ships only in the store flavor, so the community APK
carries no Google Play Billing (F-Droid requirement). It is not a pub dependency yet; see
docs/DECISIONS.md for the Phase 9 wiring plan.

## Data and asset licenses

- Map and trail data: OpenStreetMap (ODbL), OpenFreeMap / OpenMapTiles, USGS (public
  domain), Mapzen / AWS Terrain Tiles, NIFC WFIGS (CC-BY), NOAA NWS, Open-Meteo. Attribution
  is shown in the app.
- Hand-drawn icons and sprite: CC-BY-SA 4.0. Bundled data authored by Affluent Labs: CC0.
