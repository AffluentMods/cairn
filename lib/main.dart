// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/diagnostics/crash_log.dart';
import 'core/diagnostics/stall_watchdog.dart';
import 'core/settings/settings_providers.dart';
import 'data/data_providers.dart';
import 'presentation/map_common/overlays/tile_proxy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final supportDir = await getApplicationSupportDirectory();

  // Local, on-device diagnostics only, no third-party crash SDK (Fix Pass 1
  // X1.3.8). Records to a capped file the user can view, share, or clear.
  await CrashLog.init(supportDir);
  final priorOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    CrashLog.instanceOrNull
        ?.record('flutter', details.exceptionAsString(), stack: details.stack);
    priorOnError?.call(details); // keep the red screen and console in debug
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    CrashLog.instanceOrNull?.record('async', error.toString(), stack: stack);
    return false; // not handled: let the platform still surface it
  };
  if (kDebugMode) StallWatchdog.start();

  // The recording service (a separate isolate) reports through this port; it
  // must exist before the app re-attaches to a service that outlived the app.
  FlutterForegroundTask.initCommunicationPort();

  // Downloaded overlay tiles live under the app support directory; the tile
  // proxy serves them before asking upstream (offline regions).
  TileProxy.instance.cacheDir = supportDir;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appSupportDirProvider.overrideWithValue(supportDir),
      ],
      child: const CairnApp(),
    ),
  );
}
