// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/library/library_screen.dart';
import '../../presentation/library/offline_regions_screen.dart';
import '../../presentation/library/track_detail_screen.dart';
import '../../presentation/map/map_screen.dart';
import '../../presentation/plan/plan_screen.dart';
import '../../presentation/record/record_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/app_shell.dart';

final _mapKey = GlobalKey<NavigatorState>(debugLabel: 'map');
final _planKey = GlobalKey<NavigatorState>(debugLabel: 'plan');
final _recordKey = GlobalKey<NavigatorState>(debugLabel: 'record');
final _libraryKey = GlobalKey<NavigatorState>(debugLabel: 'library');

/// App routing (spec Section 3). A four-branch indexed-stack shell so each tab
/// keeps its own navigation stack and scroll position.
final appRouter = GoRouter(
  initialLocation: '/map',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _mapKey,
          routes: [
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _planKey,
          routes: [
            GoRoute(path: '/plan', builder: (_, __) => const PlanScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _recordKey,
          routes: [
            GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _libraryKey,
          routes: [
            GoRoute(
              path: '/library',
              builder: (_, __) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'track/:id',
                  builder: (_, s) =>
                      TrackDetailScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'offline',
                  builder: (_, __) => const OfflineRegionsScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (_, __) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
