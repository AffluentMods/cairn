// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

import '../../core/net/arcgis_query.dart';

/// USFS EDW and other public ArcGIS layers (spec Sections 5.3, 7). All return
/// GeoJSON with no key. Field names vary per layer, so callers read them
/// tolerantly (see [pickField]).
class UsfsSource {
  UsfsSource(this._dio);

  final Dio _dio;

  static const trailsUrl =
      'https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_TrailNFSPublish_01/MapServer/0';
  static const wildernessUrl =
      'https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_Wilderness_01/MapServer/0';
  static const forestsUrl =
      'https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_ForestSystemBoundaries_01/MapServer/0';
  static const npsBoundaryUrl =
      'https://services1.arcgis.com/fBc8EJBxQRMcHlei/arcgis/rest/services/NPS_Land_Resources_Division_Boundary_and_Tract_Data_Service/FeatureServer/2';

  /// The Motor Vehicle Use Map (docs/API_NOTES.md): roads in layer 1,
  /// motorized trails in layer 2, each segment with its vehicle classes,
  /// seasons, surface, and maintenance level.
  static const mvumRoadsUrl =
      'https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_MVUM_01/MapServer/1';
  static const mvumTrailsUrl =
      'https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_MVUM_01/MapServer/2';

  /// The MVUM fields the parser reads; asking for these alone keeps a page
  /// to a fraction of the full record.
  static const mvumFields = 'id,name,symbol,mvum_symbol_name,seasonal,'
      'surfacetype,operationalmaintlevel,gis_miles,'
      'passengervehicle,passengervehicle_datesopen,'
      'highclearancevehicle,highclearancevehicle_datesopen,'
      'truck,truck_datesopen,motorhome,motorhome_datesopen,'
      'fourwd_gt50inches,fourwd_gt50_datesopen,atv,atv_datesopen,'
      'motorcycle,motorcycle_datesopen,otherwheeled_ohv,'
      'otherwheeled_ohv_datesopen';

  /// One page (1,000 segments at most) of MVUM roads or motorized trails in
  /// [bbox] as the raw GeoJSON body, or null when the service is unreachable.
  /// The caller parses off the UI isolate and follows `exceededTransferLimit`
  /// with the next [offset].
  Future<String?> fetchMvumPage(
    List<double> bbox, {
    required bool trails,
    int offset = 0,
  }) async {
    try {
      final uri = ArcGisQuery.features(
        trails ? mvumTrailsUrl : mvumRoadsUrl,
        bbox,
        outFields: mvumFields,
        resultRecordCount: 1000,
        resultOffset: offset,
      );
      final response = await _dio.getUri<String>(
        uri,
        options: Options(responseType: ResponseType.plain),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null && data.isNotEmpty) {
        return data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchTrails(List<double> bbox) =>
      _query(trailsUrl, bbox);
  Future<Map<String, dynamic>?> fetchWilderness(List<double> bbox) =>
      _query(wildernessUrl, bbox);
  Future<Map<String, dynamic>?> fetchForests(List<double> bbox) =>
      _query(forestsUrl, bbox);
  Future<Map<String, dynamic>?> fetchNpsBoundaries(List<double> bbox) =>
      _query(npsBoundaryUrl, bbox);

  Future<Map<String, dynamic>?> _query(String base, List<double> bbox) async {
    try {
      final uri = ArcGisQuery.features(base, bbox);
      final response = await _dio.getUri<dynamic>(uri);
      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } on DioException {
      return null; // land layers are non-critical; degrade quietly
    }
  }
}

/// Reads the first present field from a GeoJSON feature's properties, trying
/// several likely spellings. USFS/NPS layers differ in casing and naming, so we
/// probe rather than hardcode one (documented in docs/API_NOTES.md).
Object? pickField(Map<String, dynamic> properties, List<String> candidates) {
  for (final key in candidates) {
    if (properties.containsKey(key) && properties[key] != null) {
      return properties[key];
    }
    // Case-insensitive fallback.
    for (final actual in properties.keys) {
      if (actual.toLowerCase() == key.toLowerCase() &&
          properties[actual] != null) {
        return properties[actual];
      }
    }
  }
  return null;
}
