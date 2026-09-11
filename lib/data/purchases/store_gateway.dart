// SPDX-License-Identifier: GPL-3.0-or-later
import 'purchases.dart';

/// The store-only purchase gateway seam. In the DEFAULT source (community and
/// F-Droid builds) this returns null, so no Google Play billing library is ever
/// linked and the app uses the no-op gateway (always entitled).
///
/// The store build swaps this file for the RevenueCat version via
/// `tool/store_prebuild.sh` (see docs/REVENUECAT.md). That version imports
/// `purchases_flutter` and returns a real gateway. Keeping the swap here, behind
/// one function, is what lets the community APK stay free of proprietary
/// libraries (spec Section 12.3) while the store build gets real purchases.
PurchaseGateway? createStoreGateway() => null;
