// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

/// A tiny on-device tile proxy (Addendum A5.3). MapLibre Native does not
/// substitute the `{bbox-epsg-3857}` token in a raster tile URL, so ArcGIS
/// export overlays are served through here: it turns `{z}/{x}/{y}` into a Web
/// Mercator bbox, fills the token in the upstream URL, fetches it, and returns
/// the image. Loopback (127.0.0.1) only, so nothing leaves the device.
class TileProxy {
  TileProxy._();
  static final TileProxy instance = TileProxy._();

  /// Half the Web Mercator extent (meters): 2 * pi * 6378137 / 2.
  static const _shift = 20037508.342789244;

  HttpServer? _server;
  final Map<String, String> _templates = {};
  final HttpClient _client = HttpClient()
    ..userAgent = 'Cairn (contact@affluentlabs.dev)'
    ..connectionTimeout = const Duration(seconds: 15);

  /// Register an overlay's upstream template (containing `{bbox-epsg-3857}`) and
  /// get back the local XYZ URL MapLibre should use. Starts the server once.
  Future<String> register(String key, String upstreamTemplate) async {
    _templates[key] = upstreamTemplate;
    final port = await _ensureStarted();
    return 'http://127.0.0.1:$port/$key/{z}/{x}/{y}';
  }

  Future<int> _ensureStarted() async {
    final existing = _server;
    if (existing != null) return existing.port;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle);
    return server.port;
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final parts = req.uri.pathSegments;
      if (parts.length < 4) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final key = parts[0];
      final template = _templates[key];
      final z = int.tryParse(parts[1]);
      final x = int.tryParse(parts[2]);
      final y = int.tryParse(parts[3].split('.').first);
      if (template == null || z == null || x == null || y == null) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final n = 1 << z;
      final west = x / n * 2 * _shift - _shift;
      final east = (x + 1) / n * 2 * _shift - _shift;
      final north = _shift - y / n * 2 * _shift;
      final south = _shift - (y + 1) / n * 2 * _shift;
      final bbox = '${west.toStringAsFixed(2)},${south.toStringAsFixed(2)},'
          '${east.toStringAsFixed(2)},${north.toStringAsFixed(2)}';
      final url = template.replaceAll('{bbox-epsg-3857}', bbox);

      final upstream = await (await _client.getUrl(Uri.parse(url))).close();
      res.statusCode = upstream.statusCode;
      res.headers.contentType = ContentType.parse(
        upstream.headers.contentType?.mimeType ?? 'image/png',
      );
      await upstream.pipe(res);
    } catch (_) {
      try {
        res.statusCode = HttpStatus.internalServerError;
        await res.close();
      } catch (_) {}
    }
  }
}
