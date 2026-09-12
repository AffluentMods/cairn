<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Cairn security audit (2026-09)

Pre-release audit using the Affluent Labs security-audit skill. Scope: the Flutter app, the
cairn-sync server, and the cairn-proxy server. Focus per the request: E2E sync crypto, the
accountless sync auth model, on-device data handling and permissions, and the proxy.

Evidence tags: Verified (executed/tested), Reviewed (read the code), Asserted (design intent),
Unverified (needs a device or live service).

## Threat model (short)

- **Assets:** the user's routes and tracks (on device), and their encrypted sync blob.
- **Trust boundaries:** device <-> public data sources (coordinates only), device <-> optional
  proxy (coordinates only), device <-> optional sync server (ciphertext only).
- **Accountless sync:** identity is a 256-bit random sync id used as a bearer token. Knowing
  the sync id lets someone PULL the encrypted blob and read STATUS, but not overwrite or purge
  (those require the password-derived verification hash). The blob is AES-256-GCM; the key is a
  DEK wrapped by an Argon2id master key. The server never sees plaintext, the passphrase, or the
  key.
- **Key residual risk (accepted, documented):** a leaked sync id exposes the salt, Argon2id
  params, and wrapped DEK, enabling an OFFLINE guess of the passphrase. This is inherent to
  bring-your-own-server E2E and matches the ZestSSH model. The passphrase strength is the control.

## Findings

### Medium
1. **No passphrase strength floor on sync setup** - lib/presentation/sync/sync_screen.dart. (Reviewed)
   - Issue: enable/join accepted any passphrase, including trivially short ones.
   - Risk: with a leaked sync id, a weak passphrase is brute-forceable offline despite Argon2id.
   - Fix: FIXED. Enable/Join now require at least 10 characters, with an inline explanation that
     the passphrase is the only protection if the sync code leaks.

### Low
2. **Sync pull/status rate-limited per IP only, not per sync id** - cairn-sync. (Reviewed)
   - Impact is minor (the caller already holds the sync id, so it is their own blob), but a
     per-sync-id limit on pull would bound abuse. Push/verify/purge are already per-sync-id limited.
3. **Argon2id at OWASP minimum (19 MiB, t=2, p=1)** - lib/data/sync/sync_crypto.dart. (Reviewed)
   - Meets current guidance; consider raising memory on capable devices later. Params travel in the
     blob so a bump is backward compatible.

### Info
4. **Transitive `qs` advisory via Express 4** - cairn-sync and cairn-proxy. (Reviewed)
   - Both servers take JSON bodies, not complex query strings, so impact is low. Consider Express 5
     at a maintenance window. Reported by both backend builds.
5. **RevenueCat not yet flavor-isolated** - the store flavor's billing must be a store-only Gradle
   dependency so the community APK stays free of Google Play libraries (F-Droid). Tracked in
   docs/DECISIONS.md; community build currently links no billing at all.

## Controls verified present

- No secrets in source or git history (grep clean); no `.env` committed. (Verified)
- `android:allowBackup="false"`, `android:usesCleartextTraffic="false"`, strict network security
  config (localhost-only cleartext in debug). (Verified in manifest)
- Only MainActivity exported (LAUNCHER + a `.gpx` VIEW filter); the foreground service is
  `exported="false"`. (Verified in manifest)
- Sync credentials in `flutter_secure_storage` (OS Keystore/Keychain); `shared_preferences` holds
  only non-sensitive settings. (Reviewed)
- Only the seven declared permissions; background location requested at recording start, not
  launch. (Reviewed)
- AES-256-GCM with a fresh CSPRNG nonce per seal; no ECB, no reused nonces; wrong passphrase fails
  the GCM tag (no padding oracle). (Reviewed + unit-tested round trips)
- Server write-verification and purge use constant-time comparison of the 32-byte hash;
  strict base64 decoding. (Reviewed in cairn-sync)
- Proxy validates lat/lon ranges and park codes; no user-controlled upstream host (no SSRF);
  serves only cached public data; logs no coordinates. (Reviewed in cairn-proxy)
- Dio request logging is debug-only and never logs URLs (which carry coordinates). (Reviewed)
- GPX deep-link import validates a 20 MB size cap and parses as XML before acting. (Reviewed)

## Summary

- Total findings: 5 (Medium 1, Low 2, Info 2). No Critical or High.
- Ship-ready: yes for the community build once the release-build items below are done on a device.
- Required before store launch (need a release build or the user, not the source): build with
  `--obfuscate --split-debug-info`, `debuggable=false`, scan the release APK strings for keys,
  confirm no Play/Firebase classes in the community APK (apkanalyzer), and wire RevenueCat as a
  store-only dependency.

## Remediation

- Fixed and verified: finding 1 (passphrase floor; analyze clean, tests green).
- Proposed, not applied: findings 2 and 3 (server rate-limit granularity, Argon2 memory bump).
- Info only: findings 4 and 5.
- Cannot complete from source: the release-build hardening checks and RevenueCat wiring.

---

# Re-audit of the Fix Pass 1 surface (2026-09-12)

Fix Pass 1 added attack surface the first audit did not cover: an on-device loopback tile proxy,
a 3D WebView with a JS bridge, a local crash/stall log with sharing, theme import/export, a
debug route simulator, and follow mode / background location. The sync and proxy findings above
are unchanged. Same evidence tags: Verified / Reviewed / Asserted / Unverified.

## Threat model additions

New entry points: the loopback `HttpServer` on `127.0.0.1:<ephemeral>` (reachable by any app on
the device, since Android does not isolate localhost between apps); the 3D `WebView` (JS enabled,
`CairnBridge` channel, a bundled page plus remote HTTPS map resources); text pasted into the theme
importer; the `.cairntheme` temp file written for export; the user-typed proxy base URL; the GPX
`VIEW` intent (unchanged); `geo:` and `https:` external launches.

STRIDE on the new boundaries (recorded, including not applicable):

- Loopback proxy. Spoofing/elevation: no auth on the socket, so another local app can drive it,
  but it can only fetch templates the app registered (keyed; numeric z/x/y validated; bbox
  formatted with `toStringAsFixed`), so there is no path to an arbitrary URL. Tampering: the
  caller is the client; upstreams are trusted ESRI/USGS/NOAA hosts over HTTPS with default
  certificate validation. Disclosure: registered overlay key names only. Denial of service: a
  local app can spend the user's bandwidth and the upstream quota; responses are streamed, not
  buffered, so memory is bounded. Repudiation: not applicable (no identity).
- 3D WebView. Tampering/elevation: the only script is the bundled, SHA-256-pinned MapLibre GL JS;
  the style is a local asset; tiles, sprites, and glyphs are binary data parsed by MapLibre, never
  executed; `runJavaScript` receives only `jsonEncode` of numbers and the local style, never a
  user string; the bridge accepts only `ready` and `error` and sets two booleans. Disclosure: the
  cache is cleared and the page blanked on close. Denial of service: bounded by the 12 s timeout.
- Theme import. Tampering: schema validated (name plus nine `#RRGGBB` colors); the id is assigned
  by the app, so an import cannot overwrite another theme. Denial of service: input length and
  name length were unbounded (finding 6).
- Crash log. Disclosure: coordinates scrubbed by regex, newlines neutralized, 200-entry cap,
  app-private directory, sharing is a deliberate user action.
- Proxy base URL. Disclosure: coordinates go to whichever host the user types (by design, bring
  your own proxy); cleartext is blocked by the network security config in release. Scheme and
  shape were not validated (finding 7).

Abuse cases walked (by reading, not by exploit): a local app hammering the proxy; a malicious
pasted theme; a redirecting upstream tile server; a `javascript:` or `intent:` URL arriving from a
data feed (none is ever launched: InciWeb is a fixed `https` URL and directions are numeric); an
oversized GPX (20 MB cap from the first audit).

## Findings

### Critical, High, Medium
None.

### Low
6. **Theme import accepts unbounded input and name length.** lib/core/theme/theme_codec.dart.
   (Reviewed) A multi-megabyte or deeply nested paste spikes memory or the decoder stack (self
   denial of service), and an arbitrarily long name is stored in Drift and rendered everywhere.
   Fix: reject input over 64 KB before decoding; cap the name at 60 characters at both entry
   points (import codec and the Designer field). FIXED.
7. **Proxy base URL is not validated.** lib/core/settings/settings_providers.dart and
   settings_screen.dart. (Reviewed) Any scheme or shape was accepted: `http://` fails silently in
   release under the network security config, and a trailing slash yields `host//v1/aqi`. The
   setting also did not say that coordinates are sent to that host.
   Fix: require `https://`, normalize the trailing slash, refuse anything else with a message,
   and state what is sent in the subtitle. FIXED.
8. **Loopback tile proxy has no per-launch secret.** lib/presentation/map_common/overlays/tile_proxy.dart.
   (Reviewed) Any app on the device could request registered overlay tiles through Cairn. No data
   is exposed, but it spends the user's bandwidth and the upstream quota under Cairn's User-Agent.
   Fix: a random 128-bit token generated at start is the first path segment; requests without it
   get 404. FIXED.
9. **Sync passphrase field allows keyboard autocorrect and suggestions.**
   lib/presentation/sync/sync_screen.dart. (Reviewed) `obscureText` is set, but the keyboard's
   learning and suggestion features were left on for a secret. Fix: `autocorrect: false` and
   `enableSuggestions: false`. FIXED.
18. **3D WebView had no navigation guard.** lib/presentation/navigate/terrain_3d_screen.dart.
    (Reviewed; surfaced by the spec audit against Addendum A5.2) With JavaScript enabled and no
    `onNavigationRequest`, a redirect from any tile, sprite, or glyph host could navigate the
    WebView to an arbitrary page. Resource fetches are XHR, not navigations, so restricting
    navigation costs nothing. Fix: allow only `file:///android_asset/` and `about:blank`,
    `NavigationDecision.prevent` for everything else. FIXED.

### Info
10. **CI actions pinned by tag; no dependency updates or vulnerability scanning.**
    .github/workflows/ci.yml. (Reviewed) `actions/checkout@v4` and `subosito/flutter-action@v2`
    are tag-pinned, so a moved tag runs unreviewed code with the repository checkout. No
    Dependabot and no OSV scan. PROPOSED (CI configuration is propose-only): pin both actions by
    commit SHA, add `.github/dependabot.yml` for the `pub` and `github-actions` ecosystems
    (weekly), and add `google/osv-scanner-action` against `pubspec.lock`. Exact change, with
    the SHAs the tags resolved to on 2026-09-12:

    ```yaml
    # .github/workflows/ci.yml
    - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
    - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2
    - name: Dependency vulnerability scan
      uses: google/osv-scanner-action/osv-scanner-action@v2.5.1
      with:
        scan-args: --lockfile=pubspec.lock

    # .github/dependabot.yml
    version: 2
    updates:
      - package-ecosystem: pub
        directory: /
        schedule:
          interval: weekly
      - package-ecosystem: github-actions
        directory: /
        schedule:
          interval: weekly
    ```

    Blast radius: none at runtime; a pinned SHA must be bumped by hand (Dependabot does this for
    the `github-actions` ecosystem). Test by opening a PR and confirming the three steps run.
    Verify the osv-scanner input name against the action's README before applying.
11. **Location history is plaintext SQLite.** lib/data/db. (Reviewed) Track points are the most
    sensitive data the app holds. Accepted: app-private storage under Android file-based
    encryption, `allowBackup="false"`, and nothing leaves the device unless end-to-end sync is
    on. SQLCipher would add a native dependency for a marginal gain; revisit if any cloud backup
    path is ever added.
12. **3D view hides base-map attribution.** assets/web/terrain3d.html (`attributionControl:false`).
    (Reviewed) OpenStreetMap, OpenFreeMap, and USGS attribution is a license term and the 2D map
    shows it. Not a security issue; fixed in the UI pass.
13. **PRIVACY.md omitted three flows.** docs/PRIVACY.md. (Reviewed) The Google Maps web fallback
    for Directions (only when no `geo:` app exists, only on tap, coordinate only), the on-device
    diagnostics log (never uploaded; sharing is manual), and the loopback tile proxy (never leaves
    the device). FIXED.
14. **No screenshot prevention on the sync passphrase screen.** (Reviewed) `FLAG_SECURE` needs a
    small platform change; low value with no accounts or payments. PROPOSED only.
15. **Tapjacking not mitigated.** (Reviewed) Flutter has no per-widget
    `filterTouchesWhenObscured`; accepted for an app with no financial or destructive-by-tap flow.
16. **Dependencies behind on major versions** (73 per `dart pub outdated`). (Verified) Not a
    known vulnerability; maintenance item covered by the Dependabot proposal in 10.
17. **Proxy follows upstream redirects** (Dart `HttpClient` default). (Reviewed) Upstreams are
    fixed trusted hosts; a redirect-based SSRF would require compromising them. Accepted.

## Controls verified on the new surface

- Loopback bind only (`InternetAddress.loopbackIPv4`, ephemeral port); the network security config
  permits cleartext solely to `127.0.0.1` and `localhost` while the base config still blocks it.
  (Reviewed)
- MapLibre GL JS 4.7.1 pinned and SHA-256 verified at fetch time (`tool/fetch_maplibre_js.sh`);
  the committed copy is what ships, so builds need no network. (Reviewed)
- WebView bridge handles only `ready` and `error`; no user-controlled string reaches
  `runJavaScript`; `clearCache()` and `about:blank` on close. (Reviewed)
- Crash log: app-private path, coordinate scrub, newline neutralization, 200-entry cap,
  serialized writes; covered by test/core/crash_log_test.dart. (Verified)
- Route simulator gated by `kDebugMode` at both the Settings toggle and the source selection.
  (Reviewed)
- External launches: directions carry only numeric coordinates and a URL-encoded label; InciWeb
  is a fixed `https` URL; no feed-supplied URL is ever launched. (Verified by grep)
- Release: `--obfuscate --split-debug-info` for both artifacts in `tool/build.sh`; the symbols
  directory is gitignored. (Reviewed)
- Logging: the only `debugPrint` is the debug-gated Dio method/status logger; no `print()`.
  (Verified by grep)
- Git history: a regex scan of every commit for common credential patterns found nothing.
  (Verified; gitleaks and trufflehog are not installed here, so this is a pattern scan rather
  than an entropy scan.)
- Manifest unchanged from the first audit: backup off, cleartext off, a single exported activity
  with `taskAffinity=""` and `singleTop`, service not exported. (Reviewed)

## Summary (re-audit)

- New findings: 13 (Low 5, Info 8). Cumulative with the first audit: 18. No Critical or High.
- Nothing here was executed against a running instance; this is a code and configuration review
  plus the greps and unit tests named above.
- Ship-ready: yes for the community build. The first audit's release-build checks still apply
  before a store launch.

## Remediation (re-audit)

- Fixed and verified: 6 (import size and name caps, unit tested), 7 (proxy URL normalization,
  unit tested), 8 (proxy token, loopback end-to-end test), 9 (passphrase field flags), 13
  (PRIVACY.md), 18 (WebView navigation guard; analyzer-verified, behavior needs the phone since
  the emulator WebView has no WebGL).
- Fixed, needs manual verification: none.
- Proposed, not applied: 10 (CI pinning, Dependabot, OSV scan) and 14 (`FLAG_SECURE`).
- Accepted with a decision: 11, 15, 16, 17.
- Cannot be completed from the codebase alone: none new.

## Applied on request (2026-09-12)

The user asked for every proposed item to be applied.

- 2 (sync server): `pull` and `status` now carry per-sync-id limiters (60 per minute each), in
  addition to the IP-keyed global limiter. cairn-sync `652a41e`, 27 tests green.
- 3 (Argon2id): new setups derive with OWASP's first recommended setting, 46 MiB, t=1, p=1
  (`Argon2Params` defaults). Existing blobs carry their own parameters, so nothing re-encrypts;
  the JSON fallbacks stay at the original 19 MiB / t=2 for blobs written before parameters were
  stored. Sync round-trip tests green.
- 4 (Express): both backends moved to Express 5.2.1; 27 and 31 tests green, `npm audit` reports
  0 vulnerabilities (the transitive `qs` advisory is gone). Local commits in each repo (neither
  has a remote configured; push them when you deploy).
- 10 (CI): every action pinned to a commit SHA with the tag in a comment (`actions/checkout`,
  `subosito/flutter-action`, `actions/setup-java`, `softprops/action-gh-release`), a
  `vulnerability-scan` job running `google/osv-scanner-action` v2.5.1 against `pubspec.lock`
  (input name `scan-args` verified against the action's `action.yml`), and
  `.github/dependabot.yml` for `pub` and `github-actions`, weekly.
- 14 (`FLAG_SECURE`): the sync screen sets the flag on entry and clears it on exit through the
  existing `com.affluentlabs.cairn/screen` channel (`ScreenWake.secure`).

Release-build checks from the first audit, run locally on the obfuscated community APK
(`flutter build apk --release --flavor community --obfuscate --split-debug-info`):

- Manifest: `debuggable` absent, `allowBackup="false"`, `usesCleartextTraffic="false"`, only
  MainActivity exported. PASS.
- Strings: no Google API keys, no Stripe keys, no private key blocks, no RevenueCat or
  `purchases_flutter` symbols, no baked proxy URL. PASS.
- Play / Firebase classes: FAIL at first check, PASS after the fix. `com.google.android.gms`
  (about 450 KB of dex, plus one Firebase reference inside it) was in the community APK, pulled in
  by `geolocator_android`'s `play-services-location` dependency. The community flavor now excludes
  the `com.google.android.gms` and `com.google.firebase` Gradle groups (geolocator falls back to
  the platform LocationManager by design), and `tool/check_apk_clean.py` reads each dex file's
  class table: the rebuilt community APK defines no Play, Firebase, billing, or RevenueCat class
  (apkanalyzer agrees: the gms packages appear as referenced only, zero defined classes). The
  19 dangling type references are geolocator's unused fused client naming absent classes; the
  script reports them as a note. CI runs the script on every release build before attaching
  the APK.
