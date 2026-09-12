// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/services.dart';

/// Keeps the screen on while a recording is in the foreground (Settings >
/// Recording > Keep screen on). One tiny method channel into MainActivity
/// (FLAG_KEEP_SCREEN_ON) rather than a plugin. No-op where unsupported.
abstract final class ScreenWake {
  static const _channel = MethodChannel('com.affluentlabs.cairn/screen');

  static Future<void> keepOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on MissingPluginException {
      // not Android, or a test
    } on PlatformException {
      // ignore
    }
  }
}
