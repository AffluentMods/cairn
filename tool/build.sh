#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Produces both release artifacts (spec Section 12.3):
#   - community APK: fully unlocked, no RevenueCat, no Google services (F-Droid, GitHub)
#   - store AAB:     Summit gate on, RevenueCat wired (Google Play)
# Both obfuscated with debug symbols kept locally (debug-symbols/ is gitignored).
set -euo pipefail

V="$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)"
echo "Building Cairn $V"

echo "==> Generating code"
dart run build_runner build --delete-conflicting-outputs

echo "==> Analyze and test"
flutter analyze
flutter test

SYMBOLS="debug-symbols/$V"
mkdir -p "$SYMBOLS"

echo "==> Community APK (fully unlocked)"
flutter build apk --release --flavor community \
  --obfuscate --split-debug-info="$SYMBOLS/community"

echo "==> Store AAB (Summit gate)"
flutter build appbundle --release --flavor store --dart-define=CAIRN_STORE=true \
  --obfuscate --split-debug-info="$SYMBOLS/store"

echo ""
echo "Artifacts:"
echo "  build/app/outputs/flutter-apk/app-community-release.apk"
echo "  build/app/outputs/bundle/storeRelease/app-store-release.aab"
echo "Symbols kept in $SYMBOLS (do not commit)."
