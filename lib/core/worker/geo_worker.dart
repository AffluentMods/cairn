// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

/// Runs CPU-heavy, pure work off the UI isolate (Fix Pass 1 X1.3.1).
///
/// Every [work] closure passed here must be pure and sendable: it may touch
/// only plain data and top-level or static functions, never Drift, dart:ui, a
/// MapLibre controller, Riverpod, or a plugin. The argument the closure closes
/// over and the value it returns are deep-copied between isolates, so keep both
/// to plain data.
///
/// Build the closure in a top-level function (an `xAsync` variant next to the
/// pure function), never inside a method of a class that holds a database or a
/// controller: Dart closures share one context per scope, so a closure written
/// inside such a method captures `this` as soon as any other closure in the
/// same method touches it, and the isolate message is refused as unsendable.
/// That is exactly what silently stopped trail ingestion for new map cells
/// once (docs/DECISIONS.md).
///
/// This is a single generic seam rather than a long-lived worker: each call
/// spawns a short-lived isolate via [Isolate.run]. The heavy paths (Overpass
/// decode and parse, GeoJSON build and simplify, routing, snapping, route
/// stats, the nearby list) are one-shot and pure, so a shared mutable worker
/// buys nothing, and one facade importing every layer would invert the layer
/// graph. Each layer keeps its own async variant next to the pure function and
/// routes it through here. The one stateful cache we need, decoded DEM tiles,
/// stays on the main isolate as an LRU of already-decoded grids (see
/// TerrainTileSource). See docs/DECISIONS.md.
class GeoWorker {
  const GeoWorker._();

  /// How many calls had to run inline because their closure was unsendable.
  /// Stays zero in a correct build; the tests assert on it.
  @visibleForTesting
  static int unsendableFallbacks = 0;

  /// Runs [work] in a background isolate and returns its result. [label] names
  /// the isolate for debugging and profiling.
  ///
  /// If the closure cannot be sent (it captured a database, a controller or
  /// another isolate-bound object), the work runs on the calling isolate
  /// instead: a janky frame beats a feature that quietly stops working.
  static Future<R> run<R>(String label, FutureOr<R> Function() work) async {
    try {
      return await Isolate.run(work, debugName: 'geo:$label');
    } on ArgumentError catch (e) {
      if (!e.toString().contains('isolate message')) rethrow;
      unsendableFallbacks++;
      debugPrint('GeoWorker: "$label" closure is unsendable, running inline: '
          '$e');
      return await work();
    }
  }
}
