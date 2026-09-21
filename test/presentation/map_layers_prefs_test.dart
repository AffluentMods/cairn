// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/presentation/map_common/map_layers_provider.dart';
import 'package:cairn/presentation/map_common/overlays/overlay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression: the layer toggles and the raster overlays shared the
// `map.overlays` key, so switching radar on or off wiped the trails and POI
// switches and the map drew and fetched no trails at all.
void main() {
  group('restoreMapLayers', () {
    test('a fresh install starts with trails and points', () {
      expect(restoreMapLayers(null, null), defaultMapLayers);
    });

    test('the new key wins, even when empty (the user turned all off)', () {
      expect(restoreMapLayers(const [], const ['trails']), isEmpty);
      expect(
        restoreMapLayers(const ['fires'], const ['trails']),
        {MapOverlay.fires},
      );
    });

    test('a legacy list with layer names migrates as is', () {
      expect(
        restoreMapLayers(null, const ['trails', 'fires']),
        {MapOverlay.trails, MapOverlay.fires},
      );
    });

    test('a legacy list the overlay controller clobbered restores defaults',
        () {
      expect(restoreMapLayers(null, const []), defaultMapLayers);
      expect(
          restoreMapLayers(null, const ['radar', 'slope']), defaultMapLayers);
    });
  });

  group('restoreRasterOverlays', () {
    test('keeps only registered overlay keys from the legacy list', () {
      expect(
        restoreRasterOverlays(null, const ['trails', 'pois', 'radar']),
        {'radar'},
      );
    });

    test('the new key wins over the legacy list', () {
      expect(restoreRasterOverlays(const [], const ['radar']), isEmpty);
      expect(
        restoreRasterOverlays(const ['officialTrails'], const ['radar']),
        {'officialTrails'},
      );
    });
  });
}
