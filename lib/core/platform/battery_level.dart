// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';

/// The battery charge in percent, or null when it cannot be read. Used only to
/// record a per-hike "% per hour" locally and to drop to the Saver profile on
/// a low battery; never sent anywhere. battery_plus (BatteryManager, no Google
/// libraries) works in the main and the recording-service isolates; the sysfs
/// node is a fallback for old builds where the plugin is unavailable.
Future<int?> readBatteryPercent() async {
  try {
    final level = await Battery().batteryLevel;
    if (level >= 0 && level <= 100) return level;
  } on Exception {
    // fall through
  } on Error {
    // MissingPluginException in a test or an engine without the plugin
  }
  if (!Platform.isAndroid) return null;
  for (final path in const [
    '/sys/class/power_supply/battery/capacity',
    '/sys/class/power_supply/Battery/capacity',
  ]) {
    try {
      final f = File(path);
      if (!f.existsSync()) continue;
      final v = int.tryParse((await f.readAsString()).trim());
      if (v != null && v >= 0 && v <= 100) return v;
    } on FileSystemException {
      // try the next node
    }
  }
  return null;
}
