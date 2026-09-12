// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:gpx/gpx.dart';

/// One GPX point: position, and optionally the file's elevation and time. The
/// GPX `<ele>` is kept as gpsAltM, but route stats use DEM elevation, since GPX
/// elevation is often garbage (spec Phase 4).
class GpxPt {
  const GpxPt({required this.lat, required this.lon, this.ele, this.time});
  final double lat;
  final double lon;
  final double? ele;
  final DateTime? time;
}

class GpxTrackData {
  const GpxTrackData({this.name, required this.points});
  final String? name;
  final List<GpxPt> points;
}

class GpxRouteData {
  const GpxRouteData({this.name, required this.points});
  final String? name;
  final List<GpxPt> points;
}

/// A user waypoint, for GPX `<wpt>` import and export: `<name>`, `<desc>`
/// (the note) and `<type>` (the kind) round-trip (Addendum A4.5).
class GpxWaypoint {
  const GpxWaypoint({
    required this.lat,
    required this.lon,
    this.name,
    this.note,
    this.kind,
  });

  final double lat;
  final double lon;
  final String? name;
  final String? note;
  final String? kind;
}

/// What a GPX file yielded: tracks (`<trk>`), routes (`<rte>`) and standalone
/// waypoints (`<wpt>`), which become user pins attached to the route.
class GpxImport {
  const GpxImport({
    required this.tracks,
    required this.routes,
    this.waypoints = const [],
  });
  final List<GpxTrackData> tracks;
  final List<GpxRouteData> routes;
  final List<GpxWaypoint> waypoints;

  bool get isEmpty => tracks.isEmpty && routes.isEmpty && waypoints.isEmpty;
}

/// Parses a GPX document. Throws [FormatException] on malformed input so the UI
/// can show a clean error rather than crash (spec Phase 4 acceptance).
GpxImport parseGpx(String xml) {
  final Gpx gpx;
  try {
    gpx = GpxReader().fromString(xml);
  } catch (e) {
    throw const FormatException('Not a readable GPX file');
  }

  final tracks = <GpxTrackData>[];
  for (final trk in gpx.trks) {
    final points = <GpxPt>[];
    for (final seg in trk.trksegs) {
      for (final p in seg.trkpts) {
        final pt = _toPt(p);
        if (pt != null) points.add(pt);
      }
    }
    if (points.isNotEmpty) {
      tracks.add(GpxTrackData(name: trk.name, points: points));
    }
  }

  final routes = <GpxRouteData>[];
  for (final rte in gpx.rtes) {
    final points = <GpxPt>[];
    for (final p in rte.rtepts) {
      final pt = _toPt(p);
      if (pt != null) points.add(pt);
    }
    if (points.isNotEmpty) {
      routes.add(GpxRouteData(name: rte.name, points: points));
    }
  }

  final waypoints = <GpxWaypoint>[];
  for (final w in gpx.wpts) {
    final lat = w.lat;
    final lon = w.lon;
    if (lat == null || lon == null) continue;
    final name = w.name?.trim();
    final note = (w.desc ?? w.cmt)?.trim();
    waypoints.add(GpxWaypoint(
      lat: lat,
      lon: lon,
      name: name == null || name.isEmpty ? null : name,
      note: note == null || note.isEmpty ? null : note,
      kind: waypointKindFromGpx(w.type ?? w.sym, name: name),
    ));
  }

  return GpxImport(tracks: tracks, routes: routes, waypoints: waypoints);
}

GpxPt? _toPt(Wpt w) {
  final lat = w.lat;
  final lon = w.lon;
  if (lat == null || lon == null) return null;
  return GpxPt(lat: lat, lon: lon, ele: w.ele, time: w.time);
}

/// The user-waypoint kinds Cairn knows (Addendum A4.5).
const waypointKinds = [
  'water',
  'camp',
  'hazard',
  'viewpoint',
  'parking',
  'note'
];

/// Maps a GPX `<type>` (or `<sym>`) to a Cairn waypoint kind. Cairn's own
/// exports round-trip exactly; other apps' free-text types are matched on
/// keywords, with the pin's name as a hint, and fall back to "note".
String waypointKindFromGpx(String? type, {String? name}) {
  final t = type?.trim().toLowerCase() ?? '';
  if (waypointKinds.contains(t)) return t;
  final text = '$t ${name?.toLowerCase() ?? ''}';
  bool has(List<String> words) => words.any(text.contains);
  if (has(['water', 'spring', 'creek', 'stream', 'lake', 'river'])) {
    return 'water';
  }
  if (has(['camp', 'shelter', 'tent'])) return 'camp';
  if (has(['hazard', 'danger', 'warning', 'caution'])) return 'hazard';
  if (has(['view', 'summit', 'peak', 'photo', 'scenic'])) return 'viewpoint';
  if (has(['parking', 'trailhead'])) return 'parking';
  return 'note';
}

/// Exports a route as GPX (creator Cairn). Elevations come from the caller (DEM).
String exportRouteGpx({
  required String name,
  required List<List<double>> geometry,
  List<double>? elevations,
  List<GpxWaypoint> waypoints = const [],
}) {
  final gpx = Gpx()
    ..creator = 'Cairn'
    ..wpts = [
      for (final w in waypoints)
        Wpt(lat: w.lat, lon: w.lon, name: w.name, desc: w.note, type: w.kind),
    ]
    ..trks = [
      Trk(
        name: name,
        trksegs: [
          Trkseg(
            trkpts: [
              for (var i = 0; i < geometry.length; i++)
                Wpt(
                  lat: geometry[i][0],
                  lon: geometry[i][1],
                  ele: (elevations != null && i < elevations.length)
                      ? elevations[i]
                      : null,
                ),
            ],
          ),
        ],
      ),
    ];
  return GpxWriter().asString(gpx, pretty: true);
}

/// Exports a recorded track as GPX with timestamps.
String exportTrackGpx({required String name, required List<GpxPt> points}) {
  final gpx = Gpx()
    ..creator = 'Cairn'
    ..trks = [
      Trk(
        name: name,
        trksegs: [
          Trkseg(
            trkpts: [
              for (final p in points)
                Wpt(lat: p.lat, lon: p.lon, ele: p.ele, time: p.time),
            ],
          ),
        ],
      ),
    ];
  return GpxWriter().asString(gpx, pretty: true);
}
