// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the device reports no network at all (airplane mode, no signal).
/// MapLibre stops requesting tiles in that state, so nothing downstream would
/// ever see a failure; the layer sheet uses this to say "Needs a connection"
/// on network overlays (Addendum A5). Only the device's own connectivity
/// state is read; no request is made.
final offlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool none(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  try {
    yield none(await connectivity.checkConnectivity());
  } catch (_) {
    yield false;
  }
  await for (final results in connectivity.onConnectivityChanged) {
    yield none(results);
  }
});
