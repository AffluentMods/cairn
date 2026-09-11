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

/// What a GPX file yielded: tracks (`<trk>`) and routes (`<rte>`).
class GpxImport {
  const GpxImport({required this.tracks, required this.routes});
  final List<GpxTrackData> tracks;
  final List<GpxRouteData> routes;

  bool get isEmpty => tracks.isEmpty && routes.isEmpty;
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

  return GpxImport(tracks: tracks, routes: routes);
}

GpxPt? _toPt(Wpt w) {
  final lat = w.lat;
  final lon = w.lon;
  if (lat == null || lon == null) return null;
  return GpxPt(lat: lat, lon: lon, ele: w.ele, time: w.time);
}

/// Exports a route as GPX (creator Cairn). Elevations come from the caller (DEM).
String exportRouteGpx({
  required String name,
  required List<List<double>> geometry,
  List<double>? elevations,
}) {
  final gpx = Gpx()
    ..creator = 'Cairn'
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
