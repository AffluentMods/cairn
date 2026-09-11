// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/settings/settings_providers.dart';
import 'map_providers.dart';

/// The shared map camera. Seeded from the last persisted position and updated
/// (and persisted) whenever a mounted map settles. Because only one [CairnMap]
/// is alive at a time (Addendum A3), remounting a tab restores this view.
class CameraNotifier extends Notifier<CameraPosition> {
  @override
  CameraPosition build() => initialCamera(ref.read(sharedPreferencesProvider));

  /// Read the live controller's camera, remember it, and persist it.
  Future<void> captureFromActiveController() async {
    final controller = ref.read(mapControllerProvider);
    final cam = controller?.cameraPosition;
    if (cam == null || controller == null) return;
    state = cam;
    await persistCamera(ref.read(sharedPreferencesProvider), controller);
  }
}

final cameraProvider =
    NotifierProvider<CameraNotifier, CameraPosition>(CameraNotifier.new);
