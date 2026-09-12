// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/services.dart';

/// A file another app handed to Cairn ("Open with Cairn" on a .gpx).
class IncomingFile {
  const IncomingFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// Files delivered by Android VIEW intents (the manifest's GPX filter). The
/// launch intent's file is fetched once with [initial]; files opened while
/// the app runs arrive on [stream]. The bytes are already capped at 20 MB on
/// the native side; the importer still validates them as GPX.
abstract final class IncomingFiles {
  static const _channel = MethodChannel('com.affluentlabs.cairn/intent');
  static final _controller = StreamController<IncomingFile>.broadcast();
  static bool _listening = false;

  static Stream<IncomingFile> get stream {
    _listen();
    return _controller.stream;
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'file') {
        final f = _decode(call.arguments);
        if (f != null) _controller.add(f);
      }
    });
  }

  /// The file the app was launched with, or null.
  static Future<IncomingFile?> initial() async {
    _listen();
    try {
      return _decode(await _channel.invokeMethod<dynamic>('initialFile'));
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static IncomingFile? _decode(dynamic raw) {
    if (raw is! Map) return null;
    final bytes = raw['bytes'];
    final name = raw['name'];
    if (bytes is! Uint8List || name is! String) return null;
    return IncomingFile(name: name, bytes: bytes);
  }
}
