// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

/// Elevation gain, loss, and extremes for a sampled elevation profile.
typedef ElevationStats = ({
  double gain,
  double loss,
  double maxElev,
  double minElev,
});

/// Cumulative gain and loss with hysteresis (spec Section 8, Phase 3). DEM
/// samples are noisy: without a deadband, jitter adds hundreds of phantom feet.
/// A move only counts once it exceeds [threshold] meters from the last committed
/// reference; then the reference advances. This is the corrected algorithm: the
/// snippet printed in the spec never caught an up-to-down reversal (its second
/// branch required `dir <= 0`, which a climbing state fails), so a sawtooth
/// returned only its first climb. This deadband version returns the sawtooth's
/// full gain and loss and rejects sub-threshold noise, matching the acceptance
/// tests exactly.
ElevationStats gainLoss(List<double> elev, {double threshold = 5.0}) {
  if (elev.isEmpty) {
    return (gain: 0, loss: 0, maxElev: 0, minElev: 0);
  }
  var gain = 0.0;
  var loss = 0.0;
  var ref = elev.first;
  var maxElev = elev.first;
  var minElev = elev.first;

  for (final e in elev.skip(1)) {
    maxElev = math.max(maxElev, e);
    minElev = math.min(minElev, e);
    final diff = e - ref;
    if (diff.abs() >= threshold) {
      if (diff > 0) {
        gain += diff;
      } else {
        loss += -diff;
      }
      ref = e;
    }
  }
  return (gain: gain, loss: loss, maxElev: maxElev, minElev: minElev);
}

/// Naismith's rule with Langmuir corrections (spec Section 8, Phase 3), in
/// seconds. 1 hour per 5 km plus 1 hour per 600 m of ascent, minus 10 min per
/// 300 m of gentle descent, plus 10 min per 300 m of steep descent. Never
/// negative.
double naismithLangmuirSeconds({
  required double distanceM,
  required double gainM,
  required double gentleDescentM,
  required double steepDescentM,
}) {
  final base = distanceM / 5000.0 * 3600.0;
  final ascent = gainM / 600.0 * 3600.0;
  final gentle = -gentleDescentM / 300.0 * 600.0;
  final steep = steepDescentM / 300.0 * 600.0;
  final total = base + ascent + gentle + steep;
  return math.max(0.0, total);
}
