// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../activity/track_detail_screen.dart';

/// Detail for a saved route (Addendum A2 lists RouteDetailScreen under Saved).
/// It reuses the shared detail view with the route kind.
class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) =>
      TrackDetailScreen(id: id, kind: DetailKind.route);
}
