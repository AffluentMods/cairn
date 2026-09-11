// SPDX-License-Identifier: GPL-3.0-or-later
//
// STORE-BUILD ONLY. tool/store_prebuild.sh copies this over
// lib/data/purchases/store_gateway.dart and adds purchases_flutter to pubspec,
// so only the Google Play (store) build links RevenueCat. Do not import this
// path from app code; the community and F-Droid builds must never see it.
//
// Excluded from `flutter analyze` in the default tree (analysis_options.yaml)
// because purchases_flutter is not a default dependency. Verify it against your
// installed purchases_flutter version when you build the store flavor.
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:cairn/data/purchases/purchases.dart';

/// The Cairn Summit entitlement id, configured in the RevenueCat dashboard.
const _entitlementId = 'summit';

/// RevenueCat public SDK key, passed at build time:
///   --dart-define=CAIRN_RC_KEY=goog_xxxxxxxxxxances
const _apiKey = String.fromEnvironment('CAIRN_RC_KEY');

/// Store build: the real RevenueCat gateway. Returns null when no key is set so
/// the app falls back to the no-op (nothing crashes if the store build is run
/// without the key).
PurchaseGateway? createStoreGateway() =>
    _apiKey.isEmpty ? null : _RevenueCatGateway();

class _RevenueCatGateway implements PurchaseGateway {
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    _configured = true;
  }

  @override
  Future<bool> hasSummit() async {
    await _ensureConfigured();
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(_entitlementId);
  }

  @override
  Future<void> restore() async {
    await _ensureConfigured();
    await Purchases.restorePurchases();
  }

  @override
  Future<bool> buySummit() async {
    await _ensureConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;
      final package = current.lifetime ??
          (current.availablePackages.isNotEmpty
              ? current.availablePackages.first
              : null);
      if (package == null) return false;
      await Purchases.purchasePackage(package);
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } on PlatformException catch (e) {
      // User cancellation is not an error.
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }
}
