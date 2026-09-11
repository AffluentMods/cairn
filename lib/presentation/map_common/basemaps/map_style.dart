// SPDX-License-Identifier: GPL-3.0-or-later
import '../../../core/settings/settings.dart';

/// Presentation mapping from a [CairnMapStyle] to its bundled style asset and
/// the attribution lines to show for it. Label text is resolved from l10n at
/// the call site (styleOutdoors, styleTopo, styleSatellite).
extension CairnMapStyleX on CairnMapStyle {
  String get assetPath => switch (this) {
        CairnMapStyle.outdoors => 'assets/map_styles/outdoors.json',
        CairnMapStyle.topo => 'assets/map_styles/topo.json',
        CairnMapStyle.satellite => 'assets/map_styles/satellite.json',
      };

  /// l10n keys for the attribution control, in order, for this base style.
  /// Overlay sources (OSM trails, NIFC fires) add their own where shown.
  List<String> get attributionKeys => switch (this) {
        CairnMapStyle.outdoors => [
            'attributionOpenFreeMap',
            'attributionOsm',
            'attributionTerrain',
          ],
        CairnMapStyle.topo => [
            'attributionUsgs',
            'attributionTerrain',
          ],
        CairnMapStyle.satellite => [
            'attributionUsgs',
            'attributionTerrain',
          ],
      };
}
