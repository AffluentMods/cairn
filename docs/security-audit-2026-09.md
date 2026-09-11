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
