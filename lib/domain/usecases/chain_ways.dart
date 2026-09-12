// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/geo/haversine.dart';

/// Joins OSM ways that share a name into continuous polylines. A named trail
/// is usually split into several ways at junctions and bridges; their end
/// nodes coincide, so a greedy walk from the longest way, extending either end
/// with any unused way whose endpoint lies within [joinToleranceM], rebuilds
/// the trail as one line for the detail sheet and for Navigate. Ways that do
/// not connect (a gap, a spur, a same-named trail elsewhere) come back as
/// further chains, longest first.
List<List<List<double>>> chainWays(
  List<List<List<double>>> ways, {
  double joinToleranceM = 15,
}) {
  final pool = ways.where((w) => w.length >= 2).toList()
    ..sort(
        (a, b) => polylineLengthMeters(b).compareTo(polylineLengthMeters(a)));
  final used = List<bool>.filled(pool.length, false);
  final chains = <List<List<double>>>[];

  bool near(List<double> a, List<double> b) =>
      haversineMeters(a[0], a[1], b[0], b[1]) <= joinToleranceM;

  for (var seed = 0; seed < pool.length; seed++) {
    if (used[seed]) continue;
    used[seed] = true;
    final chain = List<List<double>>.of(pool[seed]);
    var extended = true;
    while (extended) {
      extended = false;
      for (var i = 0; i < pool.length; i++) {
        if (used[i]) continue;
        final w = pool[i];
        if (near(chain.last, w.first)) {
          chain.addAll(w.skip(1));
        } else if (near(chain.last, w.last)) {
          chain.addAll(w.reversed.skip(1));
        } else if (near(chain.first, w.last)) {
          chain.insertAll(0, w.take(w.length - 1));
        } else if (near(chain.first, w.first)) {
          chain.insertAll(0, w.reversed.take(w.length - 1));
        } else {
          continue;
        }
        used[i] = true;
        extended = true;
      }
    }
    chains.add(chain);
  }
  chains.sort(
      (a, b) => polylineLengthMeters(b).compareTo(polylineLengthMeters(a)));
  return chains;
}
