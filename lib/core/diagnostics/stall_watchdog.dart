// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'crash_log.dart';

/// A debug-only UI stall detector (Fix Pass 1 X1.3.8). A short periodic timer
/// runs on the UI isolate; when a tick lands far later than scheduled, the UI
/// isolate was blocked for that long, and the gap is logged. It does nothing
/// beyond a timestamp comparison, and it is never started in release.
class StallWatchdog {
  StallWatchdog._(this._timer);

  final Timer _timer;
  static StallWatchdog? _instance;

  static const _period = Duration(milliseconds: 100);
  // A tick this much later than scheduled means the isolate was blocked.
  static const _threshold = Duration(milliseconds: 200);

  static void start() {
    if (_instance != null) return;
    var last = DateTime.now();
    final timer = Timer.periodic(_period, (_) {
      final now = DateTime.now();
      final late = now.difference(last) - _period;
      last = now;
      if (late > _threshold) {
        CrashLog.instanceOrNull?.recordStall(late);
      }
    });
    _instance = StallWatchdog._(timer);
  }

  static void stop() {
    _instance?._timer.cancel();
    _instance = null;
  }
}
