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
- **`require_trailing_commas` and strict casts on.** Reason: spec analysis_options plus the
  Affluent Labs "zero warnings" bar. Generated files are excluded so codegen churn does not
  fight the rule.

## Sync server (addition beyond the spec's Phase 0 to 9)

- **Built an accountless, end-to-end encrypted sync server (`cairn-sync/`), modeled on Zest
  sync.** Reason: the user explicitly asked for "a backend sync server similar to my Zest
  sync." Cairn's hard rule is "no account, ever," so the identity is a client-generated
  random sync id (an opaque bearer token), not an email or password account: no Firebase, no
  Stripe. The blob model, optimistic concurrency, write-verification gate, quotas, and the
  tombstone plus newest-wins merge follow ZestSSH exactly. Sync is optional and off by
  default; the app is fully functional offline without it. AGPL-3.0-or-later, same as the
  proxy.
