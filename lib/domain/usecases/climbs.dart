// SPDX-License-Identifier: GPL-3.0-or-later

/// One sustained climb on a route: where it starts and ends along the line
/// and how much it gains (AllTrails benchmark section 6, the climb list and
/// the on-map climb pill).
class Climb {
  const Climb({
    required this.startM,
    required this.endM,
    required this.gainM,
  });

  final double startM;
  final double endM;
  final double gainM;

  double get lengthM => endM - startM;
  double get gradePercent => lengthM <= 0 ? 0 : gainM / lengthM * 100;
}

/// Finds climbs on a profile given as parallel distance (m) and elevation
/// (m) samples: a climb is a run where the grade over a sliding [windowM]
/// stays at or above [minGrade] (a dip shorter than [maxDipM] does not end
/// it), kept when it gains at least [minGainM]. Pure; runs anywhere.
List<Climb> findClimbs(
  List<double> dists,
  List<double> elevs, {
  double minGrade = 0.06,
  double windowM = 100,
  double maxDipM = 60,
  double minGainM = 30,
}) {
  if (dists.length < 3 || dists.length != elevs.length) return const [];
  final n = dists.length;

  // Smoothed grade at each sample over +/- windowM/2, with two monotonic
  // pointers so this stays O(n).
  final grade = List<double>.filled(n, 0);
  var lo = 0, hi = 0;
  for (var i = 0; i < n; i++) {
    while (lo < n - 1 && dists[lo] < dists[i] - windowM / 2) {
      lo++;
    }
    while (hi < n - 1 && dists[hi] < dists[i] + windowM / 2) {
      hi++;
    }
    final dd = dists[hi] - dists[lo];
    grade[i] = dd > 1 ? (elevs[hi] - elevs[lo]) / dd : 0;
  }

  final out = <Climb>[];
  int? start;
  var dipFrom = -1.0;
  for (var i = 0; i < n; i++) {
    final climbing = grade[i] >= minGrade;
    if (start == null) {
      if (climbing) start = i;
      continue;
    }
    if (climbing) {
      dipFrom = -1;
      continue;
    }
    // Not climbing: allow a short dip, else close the climb.
    if (dipFrom < 0) dipFrom = dists[i];
    if (dists[i] - dipFrom <= maxDipM && i < n - 1) continue;
    _close(out, dists, elevs, start, i, minGainM, windowM);
    start = null;
    dipFrom = -1;
  }
  if (start != null) {
    _close(out, dists, elevs, start, n - 1, minGainM, windowM);
  }
  return out;
}

void _close(
  List<Climb> out,
  List<double> dists,
  List<double> elevs,
  int start,
  int end,
  double minGainM,
  double windowM,
) {
  // The smoothed grade lags the terrain by half a window: walk the start
  // back to the local low point, and end at the highest sample in the run.
  var s = start;
  while (s > 0 &&
      dists[start] - dists[s - 1] <= windowM &&
      elevs[s - 1] <= elevs[s]) {
    s--;
  }
  var top = s;
  for (var i = s; i <= end; i++) {
    if (elevs[i] > elevs[top]) top = i;
  }
  final gain = elevs[top] - elevs[s];
  if (gain >= minGainM && top > s) {
    out.add(Climb(startM: dists[s], endM: dists[top], gainM: gain));
  }
}

/// The climb in progress at [progressM], or null between climbs.
Climb? climbAt(List<Climb> climbs, double progressM) {
  for (final c in climbs) {
    if (progressM >= c.startM && progressM < c.endM) return c;
  }
  return null;
}
