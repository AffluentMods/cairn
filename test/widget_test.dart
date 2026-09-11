// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/app.dart';
import 'package:cairn/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to a 4-tab shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CairnApp(),
      ),
    );
    // One frame is enough; the map platform view does not initialize in tests.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Navigate'), findsWidgets);
    expect(find.text('Saved'), findsWidgets);
    expect(find.text('Activity'), findsWidgets);
  });
}
