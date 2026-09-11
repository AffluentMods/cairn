// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// The user-waypoint kinds (Addendum A4.5), in the order shown in the editor.
const userWaypointKinds = <String>[
  'water',
  'camp',
  'hazard',
  'viewpoint',
  'parking',
  'note',
];

IconData userWaypointIcon(String kind) => switch (kind) {
      'water' => Icons.water_drop_outlined,
      'camp' => Icons.cabin_outlined,
      'hazard' => Icons.warning_amber_outlined,
      'viewpoint' => Icons.visibility_outlined,
      'parking' => Icons.local_parking_outlined,
      'note' => Icons.sticky_note_2_outlined,
      _ => Icons.place_outlined,
    };

String userWaypointColor(String kind) => switch (kind) {
      'water' => '#3FB8AF',
      'camp' => '#6B4F2A',
      'hazard' => '#F5A524',
      'viewpoint' => '#7FA36B',
      'parking' => '#5B615E',
      'note' => '#A9B0AB',
      _ => '#D9A441',
    };

String userWaypointLabel(AppLocalizations l10n, String kind) => switch (kind) {
      'water' => l10n.waypointKindWater,
      'camp' => l10n.waypointKindCamp,
      'hazard' => l10n.waypointKindHazard,
      'viewpoint' => l10n.waypointKindViewpoint,
      'parking' => l10n.waypointKindParking,
      'note' => l10n.waypointKindNote,
      _ => kind,
    };

/// GeoJSON for the `cairn-user-waypoints` runtime source: one point per pin,
/// each carrying its id (for tap-to-edit) and a color (for the circle layer).
Map<String, dynamic> userWaypointsGeoJson(List<UserWaypoint> waypoints) => {
      'type': 'FeatureCollection',
      'features': [
        for (final w in waypoints)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [w.lon, w.lat],
            },
            'properties': {
              'id': w.id,
              'kind': w.kind,
              'color': userWaypointColor(w.kind),
            },
          },
      ],
    };
