// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/services.dart';

/// MapLibre Native refuses every tile request, the loopback tile proxy's
/// included, whenever Android reports no connectivity. Downloaded overlay
/// tiles are served by that proxy, so once the map exists the app tells
/// MapLibre to assume it is connected: base-map tiles still come from its
/// offline store, and a request that cannot reach a server simply fails
/// (docs/DECISIONS.md, offline overlays). No-op where unsupported.
abstract final class MapNetwork {
  static const _channel = MethodChannel('com.affluentlabs.cairn/screen');

  static Future<void> assumeConnected() async {
    try {
      await _channel.invokeMethod<bool>('mapAssumeConnected');
    } on MissingPluginException {
      // not Android, or a test
    } on PlatformException {
      // ignore
    }
  }
}
