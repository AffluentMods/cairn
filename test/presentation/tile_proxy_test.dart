// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/presentation/map_common/overlays/tile_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serves a registered tile only when the per-launch token is present',
      () async {
    // A fake upstream on loopback that answers any request with a tiny "png".
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((req) {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('image', 'png')
        ..write('png');
      req.response.close();
    });
    addTearDown(() => upstream.close(force: true));

    final template =
        'http://127.0.0.1:${upstream.port}/export?bbox={bbox-epsg-3857}';
    final local = await TileProxy.instance.register('t', template);
    final tile = Uri.parse(local.replaceAll('{z}/{x}/{y}', '3/2/1'));
    final client = HttpClient();
    addTearDown(client.close);

    // With the token (as registered) the proxy forwards to the upstream.
    final ok = await (await client.getUrl(tile)).close();
    expect(ok.statusCode, HttpStatus.ok);
    expect(await ok.transform(const SystemEncoding().decoder).join(), 'png');

    // Without the token, the same tile is 404: another app cannot drive it.
    final noToken = Uri.parse('http://127.0.0.1:${tile.port}/t/3/2/1');
    final bad = await (await client.getUrl(noToken)).close();
    await bad.drain<void>();
    expect(bad.statusCode, HttpStatus.notFound);

    // An unknown key with a valid token is also 404.
    final unknown = tile.replace(pathSegments: [
      tile.pathSegments.first,
      'nope',
      '3',
      '2',
      '1',
    ]);
    final missing = await (await client.getUrl(unknown)).close();
    await missing.drain<void>();
    expect(missing.statusCode, HttpStatus.notFound);
  });
}
