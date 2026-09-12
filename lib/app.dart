// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/incoming_files.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_providers.dart';
import 'l10n/app_localizations.dart';
import 'presentation/navigate/recording_provider.dart';
import 'presentation/saved/gpx_import.dart';
import 'presentation/theme_providers.dart';

/// Root widget: MaterialApp.router with the selected light and dark themes,
/// following the system setting by default (spec Section 2), and the
/// localization delegates. On first frame it re-attaches to a recording that
/// outlived the app (spec Phase 6: killing the app must not end the hike) and
/// imports a GPX file the app was opened with ("Open with Cairn", Phase 4).
class CairnApp extends ConsumerStatefulWidget {
  const CairnApp({super.key});

  @override
  ConsumerState<CairnApp> createState() => _CairnAppState();
}

class _CairnAppState extends ConsumerState<CairnApp> {
  StreamSubscription<IncomingFile>? _files;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(recordingProvider.notifier).attachOnLaunch();
      final initial = await IncomingFiles.initial();
      if (initial != null) await _import(initial);
    });
    _files = IncomingFiles.stream.listen(_import);
  }

  @override
  void dispose() {
    _files?.cancel();
    super.dispose();
  }

  Future<void> _import(IncomingFile file) async {
    final context = rootNavigatorKey.currentContext;
    if (!mounted || context == null) return;
    final ok = await importGpxBytes(
      ref,
      bytes: file.bytes,
      name: file.name,
      l10n: AppLocalizations.of(context),
      messenger: rootMessengerKey.currentState,
    );
    if (ok) appRouter.go('/saved');
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final themes = ref.watch(activeThemesProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: themes.light,
      darkTheme: themes.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
