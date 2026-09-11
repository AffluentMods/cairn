// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';

/// True only in the Play Store / App Store build. Community builds (GitHub
/// Releases, F-Droid, self-compiled) are always fully unlocked. Set on the store
/// build with `--dart-define=CAIRN_STORE=true` so the same switch works on iOS
/// later without reading Android BuildConfig (spec Section 12.3).
const bool kStoreBuild =
    bool.fromEnvironment('CAIRN_STORE', defaultValue: false);

/// Everything Cairn Summit unlocks. The gate is a single call at each of the four
/// gated entry points (spec Section 12.4); everything else is never gated. Safety
/// information (fires, weather, alerts) is never behind a purchase.
abstract final class Summit {
  /// Community and self-compiled builds: always unlocked. Store build: unlocked
  /// in debug, otherwise gated on the purchase entitlement (wired in Phase 9).
  static bool unlocked({required bool hasEntitlement}) {
    if (!kStoreBuild) return true;
    if (kDebugMode) return true;
    return hasEntitlement;
  }
}
