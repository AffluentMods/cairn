// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features_flags.dart';

/// Purchase gateway abstraction. The community flavor must not link any Google
/// Play billing library (F-Droid scans the binary), so the real RevenueCat
/// implementation is a store-only artifact wired in Phase 9. Until then, and
/// always in the community flavor, the no-op gateway reports full entitlement.
///
/// Phase 9 plan (see docs/DECISIONS.md): add a store-only Gradle dependency (not
/// a pub dependency) for `purchases_flutter`, and swap `purchaseGatewayProvider`
/// for the RevenueCat implementation behind `kStoreBuild`, keeping this interface.
abstract interface class PurchaseGateway {
  /// Whether the user owns the one-time Cairn Summit unlock.
  Future<bool> hasSummit();

  /// Restore a previous purchase (Google sign-in only, no Cairn account).
  Future<void> restore();

  /// Start the one-time purchase. Returns true if the entitlement is now owned.
  Future<bool> buySummit();
}

/// Always-entitled gateway. Correct for the community flavor and debug builds.
class NoopPurchaseGateway implements PurchaseGateway {
  const NoopPurchaseGateway();

  @override
  Future<bool> hasSummit() async => true;

  @override
  Future<void> restore() async {}

  @override
  Future<bool> buySummit() async => true;
}

final purchaseGatewayProvider = Provider<PurchaseGateway>(
  (ref) => const NoopPurchaseGateway(),
);

/// Whether Summit features are unlocked for this session. Community and debug:
/// always true. Store release: gated on the entitlement (Phase 9).
final summitEntitlementProvider = FutureProvider<bool>((ref) async {
  final gateway = ref.watch(purchaseGatewayProvider);
  return gateway.hasSummit();
});

/// The single gate read at each Summit entry point (unlimited offline regions,
/// water and campsite helpers, follow-route mode, AirNow monitor). Community and
/// self-compiled builds are always unlocked; safety features are never gated.
final summitUnlockedProvider = Provider<bool>((ref) {
  if (!kStoreBuild) return true;
  final ent = ref.watch(summitEntitlementProvider);
  return Summit.unlocked(hasEntitlement: ent.valueOrNull ?? false);
});
