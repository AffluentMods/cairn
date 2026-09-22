// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/presentation/map_common/overlays/tile_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upstream URLs fill the bbox token or the z/x/y tokens', () {
    final bbox = TileProxy.upstreamUrl(
        'https://x/export?bbox={bbox-epsg-3857}&f=image', 1, 0, 0);
    // z1 tile (0,0): the north-west quarter of the world.
    expect(bbox, contains('bbox=-20037508.34,0.00,0.00,20037508.34'));
    expect(
      TileProxy.upstreamUrl('https://x/{z}/{x}/{y}.png', 12, 665, 1453),
      'https://x/12/665/1453.png',
    );
  });

  test('a downloaded tile serves from disk after the upstream is gone',
      () async {
    final dir = await Directory.systemTemp.createTemp('cairn-proxy-cache');
    addTearDown(() => dir.delete(recursive: true));
    var upstreamHits = 0;
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((req) {
      upstreamHits++;
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('image', 'png')
        ..write('png-bytes');
      req.response.close();
    });

    final proxy = TileProxy.instance;
    proxy.cacheDir = dir;
    final template = 'http://127.0.0.1:${upstream.port}/{z}/{x}/{y}.png';

    // The region download stores the tile under its own folder.
    final size = await proxy.downloadTile(
      regionId: 'region-a',
      key: 'cached',
      template: template,
      z: 12,
      x: 665,
      y: 1453,
    );
    expect(size, 'png-bytes'.length);
    expect(proxy.cachedTile('cached', 12, 665, 1453), isNotNull);
    // Already stored: no second fetch.
    expect(
      await proxy.downloadTile(
        regionId: 'region-a',
        key: 'cached',
        template: template,
        z: 12,
        x: 665,
        y: 1453,
      ),
      0,
    );
    expect(upstreamHits, 1);

    // Upstream gone: the proxy still serves the stored tile.
    await upstream.close(force: true);
    final local = await proxy.register('cached', template);
    final client = HttpClient();
    addTearDown(client.close);
    final hit = await (await client
            .getUrl(Uri.parse(local.replaceAll('{z}/{x}/{y}', '12/665/1453'))))
        .close();
    expect(hit.statusCode, HttpStatus.ok);
    expect(await hit.transform(const SystemEncoding().decoder).join(),
        'png-bytes');

    // A tile nobody downloaded fails without the upstream.
    final miss = await (await client
            .getUrl(Uri.parse(local.replaceAll('{z}/{x}/{y}', '12/665/1454'))))
        .close();
    await miss.drain<void>();
    expect(miss.statusCode, HttpStatus.internalServerError);

    // Deleting the region removes its tiles.
    await proxy.deleteRegionTiles('region-a');
    expect(proxy.cachedTile('cached', 12, 665, 1453), isNull);
    proxy.cacheDir = null;
  });
}
