// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:isolate';

/// Runs CPU-heavy, pure work off the UI isolate (Fix Pass 1 X1.3.1).
///
/// Every [work] closure passed here must be pure and sendable: it may touch
/// only plain data and top-level or static functions, never Drift, dart:ui, a
/// MapLibre controller, Riverpod, or a plugin. The argument the closure closes
/// over and the value it returns are deep-copied between isolates, so keep both
/// to plain data.
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

  /// Runs [work] in a background isolate and returns its result. [label] names
  /// the isolate for debugging and profiling.
  static Future<R> run<R>(String label, FutureOr<R> Function() work) =>
      Isolate.run(work, debugName: 'geo:$label');
}
