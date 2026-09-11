<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Cairn Summit purchases with RevenueCat

Cairn Summit is a **one-time** USD 9.99 unlock, sold only in the **store** (Google Play)
build. The community and F-Droid builds are always fully unlocked and link no billing
library. The gate is already in the code (`summitUnlockedProvider`, the Summit sheet, and the
gated entry points); this doc is the account setup and the build steps.

Summit unlocks: unlimited offline regions, the water and campsite planning helpers, follow-a-
route while recording, and EPA AirNow monitor air quality. Safety features (map, trails,
planner, recording, fires, weather, alerts, one offline region, GPX) are never gated.

---

## Part 1: Google Play Console (do this first)

1. Create the app in the [Play Console](https://play.google.com/console) with package
   `com.affluentlabs.cairn`. Complete the store listing and content rating enough to create
   products (you do not need to publish yet).
2. Monetize, then Products, then **In-app products**. Create one:
   - Product ID: **`cairn_summit_lifetime`** (must match exactly).
   - Type: one-time (managed) product.
   - Name: "Cairn Summit". Price: USD 9.99 (Play sets local prices).
   - **Activate** it.
3. Create a Google Cloud **service account** with access to the Play Developer API and grant
   it to this app (Play Console, Users and permissions), so RevenueCat can verify purchases.
   RevenueCat's Play setup guide walks through the exact clicks.

## Part 2: RevenueCat dashboard

1. Create a free account at [revenuecat.com](https://www.revenuecat.com), then a **Project**
   ("Cairn").
2. Add an **App**: platform Google Play, package `com.affluentlabs.cairn`. Upload the Play
   service account credentials from Part 1.
3. **Products**: add the product `cairn_summit_lifetime` (import from Play or add by id).
4. **Entitlements**: create one with identifier **`summit`** (must match the code). Attach the
   `cairn_summit_lifetime` product to it.
5. **Offerings**: the `default` offering is fine. Add a **Package** to it (type "Lifetime" is
   the natural fit) containing `cairn_summit_lifetime`. The app buys `current.lifetime` (or
   the first available package).
6. **API keys**: copy the **public Google/Android SDK key** (starts with `goog_`). This is the
   value you pass at build time. It is a public client key, safe in the binary.

## Part 3: Build the store app

From a clean checkout:

```bash
tool/store_prebuild.sh          # adds purchases_flutter, swaps in the RevenueCat gateway
flutter analyze                 # optional; the store gateway is now live
flutter build appbundle --release --flavor store \
  --dart-define=CAIRN_STORE=true \
  --dart-define=CAIRN_RC_KEY=goog_your_key_here \
  --obfuscate --split-debug-info=debug-symbols/store
```

Upload `build/app/outputs/bundle/storeRelease/app-store-release.aab` to Play.

To return to the clean community/F-Droid tree afterward:

```bash
git checkout lib/data/purchases/store_gateway.dart pubspec.yaml pubspec.lock
```

The community build never runs the prebuild:

```bash
flutter build apk --release --flavor community \
  --obfuscate --split-debug-info=debug-symbols/community
```

## How the F-Droid-clean split works

- `purchases_flutter` is **not** a default dependency, so the community and F-Droid builds
  contain no Google Play Billing library (F-Droid scans the binary, not intentions).
- `lib/data/purchases/store_gateway.dart` in the default tree returns `null`, so the app uses
  the always-entitled no-op gateway.
- `tool/store_prebuild.sh` swaps in `tool/store-build/store_gateway.dart` (the real RevenueCat
  gateway) and adds the dependency, for the store build only. `tool/store-build/**` is
  excluded from `flutter analyze` in the default tree because it imports a package that is not
  present there.
- The Summit sheet and gates call the abstract `PurchaseGateway`, so nothing in the app's UI
  code references RevenueCat directly.

## Testing the purchase

Use a Play **internal testing** track and a license-tester account, or RevenueCat's sandbox.
Buy, then uninstall and reinstall and tap **Restore** on the Summit sheet: the entitlement
should come back. In any **debug** build both flavors are fully unlocked, so test the paywall
UI itself in a release store build.

## Verify against your SDK version

`tool/store-build/store_gateway.dart` targets the `purchases_flutter` 10.x API
(`Purchases.configure`, `getOfferings`, `purchasePackage`, `getCustomerInfo`,
`restorePurchases`). If `flutter pub add purchases_flutter` resolves a different major, check
those call signatures once when you first build the store flavor.
