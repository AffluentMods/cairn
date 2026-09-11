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

## Questions for you

Collected here so you can answer them all at once when you are back. See the bottom of this
file. Nothing below blocked the build; each has a shipped default.

---

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
