#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Prepares the tree for a STORE build: adds purchases_flutter and swaps in the
# RevenueCat gateway. Run this ONLY before building the store flavor. The
# community and F-Droid builds must be built from the clean tree (do not run
# this, or run tool/store_unprebuild.sh to undo it).
#
#   tool/store_prebuild.sh
#   flutter build appbundle --release --flavor store \
#     --dart-define=CAIRN_STORE=true \
#     --dart-define=CAIRN_RC_KEY=goog_your_revenuecat_key \
#     --obfuscate --split-debug-info=debug-symbols/store
set -euo pipefail

echo "==> Adding purchases_flutter"
flutter pub add purchases_flutter

echo "==> Swapping in the RevenueCat gateway"
cp tool/store-build/store_gateway.dart lib/data/purchases/store_gateway.dart

echo ""
echo "Store build is ready. Now build with --flavor store and both dart-defines"
echo "(CAIRN_STORE=true and CAIRN_RC_KEY=...). To return to the clean tree:"
echo "  git checkout lib/data/purchases/store_gateway.dart pubspec.yaml pubspec.lock"
