// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to a 4-tab shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CairnApp()));
    await tester.pumpAndSettle();

    // The bottom navigation shows all four tabs.
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

    // Map is the initial tab.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
