// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/activity/activity_screen.dart';
import '../../presentation/activity/track_detail_screen.dart';
import '../../presentation/explore/explore_screen.dart';
import '../../presentation/navigate/navigate_screen.dart';
import '../../presentation/navigate/terrain_3d_screen.dart';
import '../../presentation/saved/offline_regions_screen.dart';
import '../../presentation/saved/route_detail_screen.dart';
import '../../presentation/saved/saved_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/sync/sync_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App routing (Addendum A3). A four-branch indexed-stack shell: Explore,
/// Navigate, Saved, Activity. Full-screen pushes (3D, Settings, Sync) use the
/// root navigator so they cover the bottom bar.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/explore',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (_, __) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/navigate',
              builder: (_, __) => const NavigateScreen(),
              routes: [
                GoRoute(
                  path: '3d',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, __) => const Terrain3dScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved',
              builder: (_, __) => const SavedScreen(),
              routes: [
                GoRoute(
                  path: 'route/:id',
                  builder: (_, s) =>
                      RouteDetailScreen(id: s.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'offline',
                  builder: (_, __) => const OfflineRegionsScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, __) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'sync',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, __) => const SyncScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (_, __) => const ActivityScreen(),
              routes: [
                GoRoute(
                  path: 'track/:id',
                  builder: (_, s) => TrackDetailScreen(
                    id: s.pathParameters['id']!,
                    kind: DetailKind.track,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
