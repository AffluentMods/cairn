// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/worker/geo_worker.dart';
import '../../../domain/usecases/compute_route_stats.dart';

/// A prepared, paint-ready view of an elevation profile (Fix Pass 1 X2.5):
/// downsampled to about one point per pixel with a smoothed grade class per
/// segment, so the painter does no per-frame reshaping. Built in a worker.
class ProfileView {
  const ProfileView({
    required this.dist,
    required this.elev,
    required this.segmentGrade,
    required this.minE,
    required this.maxE,
  });

  /// Downsampled distances (meters) and elevations (meters), parallel arrays.
  final List<double> dist;
  final List<double> elev;

  /// Grade class per segment (length == dist.length - 1): 0 gentle, 1 moderate,
  /// 2 steep, smoothed over a 100 m window so noise does not stripe the line.
  final List<int> segmentGrade;

  final double minE;
  final double maxE;

  bool get isUsable => dist.length >= 2;
}

/// Builds a [ProfileView] from a raw profile, downsampling to [targetPixels] and
/// smoothing grade over a 100 m window merged into runs. Pure and top-level so
/// it runs in a worker isolate.
ProfileView buildProfileView(List<ProfilePoint> profile, int targetPixels) {
  if (profile.length < 2) {
    return const ProfileView(
        dist: [], elev: [], segmentGrade: [], minE: 0, maxE: 0);
  }
  final target = targetPixels.clamp(2, 4096);
  final step = profile.length <= target ? 1.0 : profile.length / target;
  final dist = <double>[];
  final elev = <double>[];
  if (step == 1.0) {
    for (final p in profile) {
      dist.add(p.distanceM);
      elev.add(p.elevM);
    }
  } else {
    for (var i = 0; i < target; i++) {
      final p = profile[(i * step).floor()];
      dist.add(p.distanceM);
      elev.add(p.elevM);
    }
    dist.add(profile.last.distanceM);
    elev.add(profile.last.elevM);
  }

  var minE = elev.first, maxE = elev.first;
  for (final e in elev) {
    if (e < minE) minE = e;
    if (e > maxE) maxE = e;
  }

  // Smoothed grade per segment over a +/- 50 m window, with two monotonic
  // pointers so this stays O(n).
  final seg = List<int>.filled(dist.length - 1, 0);
  var lo = 0, hi = 0;
  for (var i = 0; i < dist.length - 1; i++) {
    final center = (dist[i] + dist[i + 1]) / 2;
    while (lo < dist.length - 1 && dist[lo] < center - 50) {
      lo++;
    }
    while (hi < dist.length - 1 && dist[hi] < center + 50) {
      hi++;
    }
    final dd = dist[hi] - dist[lo];
    final grade = dd > 1 ? (elev[hi] - elev[lo]).abs() / dd : 0.0;
    seg[i] = grade > 0.15
        ? 2
        : grade > 0.08
            ? 1
            : 0;
  }

  return ProfileView(
    dist: dist,
    elev: elev,
    segmentGrade: seg,
    minE: minE,
    maxE: maxE,
  );
}

Future<ProfileView> buildProfileViewAsync(
  List<ProfilePoint> profile,
  int targetPixels,
) =>
    GeoWorker.run(
        'profile-view', () => buildProfileView(profile, targetPixels));

/// The elevation profile (spec Section 9.4, Fix Pass 1 X2.5): a single neutral
/// area fill with an accent progress fill up to the scrubber, a grade-colored
/// line (green under 8 percent, amber 8 to 15, red over 15) drawn as runs, and
/// non-overlapping min/max labels in the right gutter. A drag reports the
/// distance so the map can move a marker.
class ElevationProfile extends ConsumerStatefulWidget {
  const ElevationProfile({
    required this.profile,
    this.onScrub,
    this.progressDistanceM,
    super.key,
  });

  final List<ProfilePoint> profile;

  /// Called with the scrubbed distance (meters), or null when the touch ends.
  final ValueChanged<double?>? onScrub;

  /// While recording along this route: distance covered, drawn as the accent
  /// fill with a position dot when nothing is being scrubbed.
  final double? progressDistanceM;

  @override
  ConsumerState<ElevationProfile> createState() => _ElevationProfileState();
}

class _ElevationProfileState extends ConsumerState<ElevationProfile> {
  double? _scrubX;

  // Memoized worker result, keyed by the profile identity and rounded width.
  List<ProfilePoint>? _forProfile;
  int _forWidth = 0;
  Future<ProfileView>? _future;
  ProfileView? _lastView;

  void _emit(double? x, double width) {
    setState(() => _scrubX = x);
    final cb = widget.onScrub;
    if (cb == null) return;
    if (x == null || widget.profile.isEmpty) {
      cb(null);
      return;
    }
    final total = widget.profile.last.distanceM;
    cb((x / width).clamp(0.0, 1.0) * total);
  }

  Future<ProfileView> _viewFor(int targetPixels) {
    if (!identical(_forProfile, widget.profile) ||
        (targetPixels - _forWidth).abs() > 48) {
      _forProfile = widget.profile;
      _forWidth = targetPixels;
      _future = buildProfileViewAsync(widget.profile, targetPixels)
        ..then((v) {
          if (mounted) setState(() => _lastView = v);
        });
    }
    return _future!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile.length < 2) return const SizedBox(height: 140);
    final theme = Theme.of(context);
    final fmt = ref.watch(unitFormatterProvider);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return SizedBox(
      height: 140,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final future = _viewFor((w * dpr).round());
          return GestureDetector(
            onHorizontalDragStart: (d) => _emit(d.localPosition.dx, w),
            onHorizontalDragUpdate: (d) => _emit(d.localPosition.dx, w),
            onHorizontalDragEnd: (_) => _emit(null, w),
            onTapDown: (d) => _emit(d.localPosition.dx, w),
            onTapUp: (_) => _emit(null, w),
            child: FutureBuilder<ProfileView>(
              future: future,
              builder: (context, snapshot) {
                final view = snapshot.data ?? _lastView;
                if (view == null || !view.isUsable) {
                  return const SizedBox(height: 140);
                }
                final total = widget.profile.last.distanceM;
                final progress = widget.progressDistanceM;
                final progressX = progress == null || total <= 0
                    ? null
                    : (progress / total).clamp(0.0, 1.0) * w;
                return CustomPaint(
                  size: Size(w, 140),
                  painter: _ProfilePainter(
                    view: view,
                    scrubX: _scrubX,
                    progressX: progressX,
                    textColor: theme.colorScheme.onSurfaceVariant,
                    neutralColor: theme.colorScheme.onSurfaceVariant,
                    accentColor: theme.colorScheme.primary,
                    formatElev: fmt.elevation,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.view,
    required this.scrubX,
    required this.textColor,
    required this.neutralColor,
    required this.accentColor,
    required this.formatElev,
    this.progressX,
  });

  final ProfileView view;
  final double? scrubX;
  final double? progressX;
  final Color textColor;
  final Color neutralColor;
  final Color accentColor;
  final String Function(double meters) formatElev;

  static const _gradeColors = [
    AppColors.aqiGood, // gentle
    AppColors.smoke, // moderate
    AppColors.fire, // steep
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dist = view.dist;
    final elev = view.elev;
    final totalD = dist.last == 0 ? 1.0 : dist.last;
    final range =
        (view.maxE - view.minE).abs() < 1 ? 1.0 : view.maxE - view.minE;

    double xOf(double d) => d / totalD * size.width;
    double yOf(double e) =>
        size.height - 8 - (e - view.minE) / range * (size.height - 24);

    final offsets = [
      for (var i = 0; i < dist.length; i++) Offset(xOf(dist[i]), yOf(elev[i])),
    ];

    // One neutral area fill for the whole profile.
    final area = Path()..moveTo(offsets.first.dx, size.height);
    for (final o in offsets) {
      area.lineTo(o.dx, o.dy);
    }
    area
      ..lineTo(offsets.last.dx, size.height)
      ..close();
    canvas.drawPath(
        area, Paint()..color = neutralColor.withValues(alpha: 0.10));

    // One accent progress fill, clipped to the left of the scrubber, or of
    // the recorded progress when nothing is being scrubbed.
    final fillX = scrubX ?? progressX;
    if (fillX != null) {
      final x = fillX.clamp(0.0, size.width);
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, x, size.height));
      canvas.drawPath(
          area, Paint()..color = accentColor.withValues(alpha: 0.20));
      canvas.restore();
    }

    // Grade-colored line, drawn as runs of the same class (no per-sample fills).
    var runStart = 0;
    while (runStart < view.segmentGrade.length) {
      final cls = view.segmentGrade[runStart];
      var runEnd = runStart;
      while (runEnd < view.segmentGrade.length &&
          view.segmentGrade[runEnd] == cls) {
        runEnd++;
      }
      final path = Path()..moveTo(offsets[runStart].dx, offsets[runStart].dy);
      for (var i = runStart + 1; i <= runEnd; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..color = _gradeColors[cls]
          ..strokeWidth = 2.5,
      );
      runStart = runEnd;
    }

    // Min and max labels in the right gutter: max at the top, min at the
    // bottom, so they never overlap each other or the line.
    _label(canvas, size, formatElev(view.maxE), top: true);
    _label(canvas, size, formatElev(view.minE), top: false);

    if (scrubX != null) {
      final x = scrubX!.clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = accentColor
          ..strokeWidth = 1.5,
      );
      // A dot where the scrubber meets the line.
      final frac = (x / size.width).clamp(0.0, 1.0);
      final e = _elevAtFraction(frac);
      canvas.drawCircle(
        Offset(x, yOf(e)),
        4,
        Paint()..color = accentColor,
      );
    } else if (progressX != null) {
      // "You are here" while recording: a ringed dot on the line.
      final x = progressX!.clamp(0.0, size.width);
      final e = _elevAtFraction((x / size.width).clamp(0.0, 1.0));
      final c = Offset(x, yOf(e));
      canvas.drawCircle(
          c, 6, Paint()..color = accentColor.withValues(alpha: 0.35));
      canvas.drawCircle(c, 3.5, Paint()..color = accentColor);
    }
  }

  double _elevAtFraction(double frac) {
    final d = frac * (view.dist.last);
    // Linear scan is fine: dist is downsampled to at most a few thousand and
    // this runs once per frame only while scrubbing.
    for (var i = 0; i < view.dist.length - 1; i++) {
      if (d <= view.dist[i + 1]) {
        final span = view.dist[i + 1] - view.dist[i];
        final t = span > 0 ? (d - view.dist[i]) / span : 0.0;
        return view.elev[i] + (view.elev[i + 1] - view.elev[i]) * t;
      }
    }
    return view.elev.last;
  }

  void _label(Canvas canvas, Size size, String text, {required bool top}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 11, // the spec's floor (Section 9.2)
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = size.width - tp.width - 4;
    final y = top ? 2.0 : size.height - tp.height - 2;
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      !identical(old.view, view) ||
      old.scrubX != scrubX ||
      old.progressX != progressX;
}
