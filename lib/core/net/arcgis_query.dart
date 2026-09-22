// SPDX-License-Identifier: GPL-3.0-or-later

/// Builds ArcGIS REST `query` URLs for the USFS, NIFC, NPS, and state layers
/// (spec Sections 5.3, 5.4, 7). All of these accept `f=geojson` and a bounding
/// box envelope in WGS84.
class ArcGisQuery {
  const ArcGisQuery._();

  /// A feature query over a bounding box (south, west, north, east), returning
  /// GeoJSON in WGS84. [where] defaults to everything.
  static Uri features(
    String baseUrl,
    List<double> bbox, {
    String where = '1=1',
    String outFields = '*',
    int? resultRecordCount,
    int? resultOffset,
  }) {
    final xmin = bbox[1];
    final ymin = bbox[0];
    final xmax = bbox[3];
    final ymax = bbox[2];
    final params = <String, String>{
      'where': where,
      'geometry': '$xmin,$ymin,$xmax,$ymax',
      'geometryType': 'esriGeometryEnvelope',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'outFields': outFields,
      'outSR': '4326',
      'f': 'geojson',
      'returnGeometry': 'true',
      if (resultRecordCount != null) 'resultRecordCount': '$resultRecordCount',
      if (resultOffset != null) 'resultOffset': '$resultOffset',
    };
    return Uri.parse('$baseUrl/query').replace(queryParameters: params);
  }

  /// The layer metadata URL (`?f=json`), used once to discover real field names
  /// and write them into docs/API_NOTES.md.
  static Uri metadata(String baseUrl) =>
      Uri.parse(baseUrl).replace(queryParameters: {'f': 'json'});
}
