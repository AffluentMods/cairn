// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/offline_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay tiles count every zoom in the range and none outside it', () {
    const bbox = [46.40, -121.60, 46.60, -121.30];
    final z12 = overlayTileCount(bbox, minZoom: 12, maxZoom: 12);
    final z12to14 = overlayTileCount(bbox, minZoom: 12, maxZoom: 14);
    expect(z12, greaterThan(0));
    // Each zoom roughly quadruples the count.
    expect(z12to14, greaterThan(z12 * 10));
    expect(overlayTileCount(bbox, minZoom: 14, maxZoom: 12), 0);
  });

  final bbox = [46.4, -121.55, 46.55, -121.35];

  test('a real region has a positive estimate', () {
    final e = estimateRegionBytes(
      bbox,
      minZoom: 10,
      maxZoom: 14,
      vectorStyles: 1,
    );
    expect(e.bytes, greaterThan(0));
    expect(e.tileCount, greaterThan(0));
  });

  test('more zoom means more bytes', () {
    final low =
        estimateRegionBytes(bbox, minZoom: 10, maxZoom: 12, vectorStyles: 1);
    final high =
        estimateRegionBytes(bbox, minZoom: 10, maxZoom: 15, vectorStyles: 1);
    expect(high.bytes, greaterThan(low.bytes));
  });

  test('raster styles cost more per tile than vector', () {
    final vector =
        estimateRegionBytes(bbox, minZoom: 10, maxZoom: 14, vectorStyles: 1);
    final raster =
        estimateRegionBytes(bbox, minZoom: 10, maxZoom: 14, rasterStyles: 1);
    expect(raster.bytes, greaterThan(vector.bytes));
  });

  test('a huge region is flagged large', () {
    final huge = estimateRegionBytes(
      [45.0, -123.0, 48.0, -119.0],
      minZoom: 10,
      maxZoom: 16,
      vectorStyles: 1,
      rasterStyles: 2,
    );
    expect(huge.isLarge, isTrue);
  });
}
