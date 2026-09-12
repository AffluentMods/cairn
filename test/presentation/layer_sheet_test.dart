// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/net/connectivity_provider.dart';
import 'package:cairn/core/settings/settings_providers.dart';
import 'package:cairn/l10n/app_localizations.dart';
import 'package:cairn/presentation/map_common/widgets/layer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Addendum A5: the layer sheet at 360x640 logical px with the text scaled
  // 1.3x must lay out without overflow errors.
  testWidgets('layer sheet fits a small phone at 1.3x text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);

    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          offlineProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(body: LayerSheet(scrollController: scroll)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Outdoors'), findsOneWidget);

    // Every overlay row is reachable by scrolling, still without overflow.
    await tester.scrollUntilVisible(
      find.text('OSM GPS traces'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('OSM GPS traces'), findsOneWidget);
  });
}
