// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:path/path.dart' as p;

/// A tiny on-device tile proxy (Addendum A5.3). MapLibre Native does not
/// substitute the `{bbox-epsg-3857}` token in a raster tile URL, so ArcGIS
/// export overlays are served through here: it turns `{z}/{x}/{y}` into a Web
/// Mercator bbox, fills the token in the upstream URL, fetches it, and returns
/// the image. Loopback (127.0.0.1) only, so nothing leaves the device.
///
/// It is also the offline store for raster overlays: an offline region
/// downloads its overlay tiles into the app support directory under
/// `overlay-tiles/REGION/KEY/z/x/y.png`, and the proxy serves a stored tile
/// before asking upstream, so a downloaded overlay draws with no signal.
/// Deleting the region deletes its folder. Plain XYZ overlays go through here
/// too for the same reason.
class TileProxy {
  TileProxy._();
  static final TileProxy instance = TileProxy._();

  /// Half the Web Mercator extent (meters): 2 * pi * 6378137 / 2.
  static const _shift = 20037508.342789244;

  /// Where downloaded overlay tiles live; set once the app support directory
  /// is known. Without it the proxy only forwards.
  Directory? cacheDir;

  HttpServer? _server;
  final Map<String, String> _templates = {};

  /// Region folders under the tile store, most recently touched last; listed
  /// once and kept current by downloads and deletes.
  List<String>? _regionDirs;

  /// Overlay keys whose last upstream fetch failed (offline, or the service
  /// down). The layer sheet shows "Needs a connection" for these (Addendum
  /// A5); a later successful tile clears the key.
  final ValueNotifier<Set<String>> offline = ValueNotifier(const {});

  void _markOffline(String key, bool failed) {
    final current = offline.value;
    if (failed == current.contains(key)) return;
    offline.value = failed ? {...current, key} : ({...current}..remove(key));
  }

  /// A random per-launch secret that must be the first path segment. Android
  /// does not isolate localhost between apps, so without it any app on the
  /// device could drive this proxy (security re-audit, finding 8).
  final String _token = _newToken();

  static String _newToken() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  final HttpClient _client = HttpClient()
    ..userAgent = 'Cairn (contact@affluentlabs.dev)'
    ..connectionTimeout = const Duration(seconds: 15);

  /// Register an overlay's upstream template (containing `{bbox-epsg-3857}`
  /// or `{z}/{x}/{y}`) and get back the local XYZ URL MapLibre should use.
  /// Starts the server once.
  Future<String> register(String key, String upstreamTemplate) async {
    _templates[key] = upstreamTemplate;
    final port = await _ensureStarted();
    return 'http://127.0.0.1:$port/$_token/$key/{z}/{x}/{y}';
  }

  Future<int> _ensureStarted() async {
    final existing = _server;
    if (existing != null) return existing.port;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle);
    return server.port;
  }

  /// The upstream URL for one tile of [template]: the bbox token filled with
  /// the tile's Web Mercator extent, or the z/x/y tokens substituted.
  static String upstreamUrl(String template, int z, int x, int y) {
    if (template.contains('{bbox-epsg-3857}')) {
      final n = 1 << z;
      final west = x / n * 2 * _shift - _shift;
      final east = (x + 1) / n * 2 * _shift - _shift;
      final north = _shift - y / n * 2 * _shift;
      final south = _shift - (y + 1) / n * 2 * _shift;
      final bbox = '${west.toStringAsFixed(2)},${south.toStringAsFixed(2)},'
          '${east.toStringAsFixed(2)},${north.toStringAsFixed(2)}';
      return template.replaceAll('{bbox-epsg-3857}', bbox);
    }
    return template
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  Directory? get _store {
    final dir = cacheDir;
    return dir == null ? null : Directory(p.join(dir.path, 'overlay-tiles'));
  }

  List<String> _regions() {
    final cached = _regionDirs;
    if (cached != null) return cached;
    final store = _store;
    final dirs = <String>[];
    if (store != null && store.existsSync()) {
      for (final e in store.listSync()) {
        if (e is Directory) dirs.add(p.basename(e.path));
      }
    }
    return _regionDirs = dirs;
  }

  File _tileFile(String regionId, String key, int z, int x, int y) =>
      File(p.join(_store!.path, regionId, key, '$z', '$x', '$y.png'));

  /// A downloaded copy of the tile from any region, or null.
  File? cachedTile(String key, int z, int x, int y) {
    if (_store == null) return null;
    for (final region in _regions()) {
      final f = _tileFile(region, key, z, x, y);
      if (f.existsSync()) return f;
    }
    return null;
  }

  /// Fetches one tile of [template] for an offline region and stores it under
  /// the region's folder. Returns the tile's size in bytes, 0 when it was
  /// already stored, or null when the fetch failed (the caller keeps going;
  /// a later Resume fills the gaps).
  Future<int?> downloadTile({
    required String regionId,
    required String key,
    required String template,
    required int z,
    required int x,
    required int y,
  }) async {
    if (_store == null) return null;
    final file = _tileFile(regionId, key, z, x, y);
    if (file.existsSync()) return 0;
    try {
      final upstream = await (await _client
              .getUrl(Uri.parse(upstreamUrl(template, z, x, y))))
          .close();
      if (upstream.statusCode != HttpStatus.ok) {
        await upstream.drain<void>();
        return null;
      }
      final bytes = await upstream.fold<List<int>>([], (a, b) => a..addAll(b));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      final regions = _regions();
      if (!regions.contains(regionId)) regions.add(regionId);
      return bytes.length;
    } on IOException {
      return null;
    }
  }

  /// Removes every overlay tile an offline region downloaded.
  Future<void> deleteRegionTiles(String regionId) async {
    final store = _store;
    if (store == null) return;
    final dir = Directory(p.join(store.path, regionId));
    if (dir.existsSync()) await dir.delete(recursive: true);
    _regionDirs?.remove(regionId);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final parts = req.uri.pathSegments;
      // Token first, then key/z/x/y. Anything else is 404, including requests
      // from other apps that do not know this launch's token.
      if (parts.length < 5 || parts[0] != _token) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final key = parts[1];
      final template = _templates[key];
      final z = int.tryParse(parts[2]);
      final x = int.tryParse(parts[3]);
      final y = int.tryParse(parts[4].split('.').first);
      if (template == null || z == null || x == null || y == null) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }

      // A tile an offline region downloaded serves without the network.
      final stored = cachedTile(key, z, x, y);
      if (stored != null) {
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType('image', 'png');
        await res.addStream(stored.openRead());
        await res.close();
        _markOffline(key, false);
        return;
      }

      final url = upstreamUrl(template, z, x, y);
      try {
        final upstream = await (await _client.getUrl(Uri.parse(url))).close();
        res.statusCode = upstream.statusCode;
        res.headers.contentType = ContentType.parse(
          upstream.headers.contentType?.mimeType ?? 'image/png',
        );
        _markOffline(key, upstream.statusCode >= 500);
        await upstream.pipe(res);
      } on IOException {
        // No route to the service: the tile fails and the sheet says so.
        _markOffline(key, true);
        rethrow;
      }
    } catch (_) {
      try {
        res.statusCode = HttpStatus.internalServerError;
        await res.close();
      } catch (_) {}
    }
  }
}
