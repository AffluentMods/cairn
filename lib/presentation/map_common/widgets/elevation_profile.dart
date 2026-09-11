// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/usecases/compute_route_stats.dart';

/// The elevation profile (spec Section 9.4): 140 dp, filled area under the line,
/// colored by grade (green under 8 percent, amber 8 to 15, red over 15), a
/// draggable scrubber that reports the distance so the map can move a marker.
class ElevationProfile extends StatefulWidget {
  const ElevationProfile({
    required this.profile,
    this.onScrub,
    super.key,
  });

  final List<ProfilePoint> profile;

  /// Called with the scrubbed distance (meters), or null when the touch ends.
  final ValueChanged<double?>? onScrub;

  @override
  State<ElevationProfile> createState() => _ElevationProfileState();
}

class _ElevationProfileState extends State<ElevationProfile> {
  double? _scrubX;

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

  @override
  Widget build(BuildContext context) {
    if (widget.profile.length < 2) return const SizedBox(height: 140);
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragStart: (d) => _emit(d.localPosition.dx, w),
            onHorizontalDragUpdate: (d) => _emit(d.localPosition.dx, w),
            onHorizontalDragEnd: (_) => _emit(null, w),
            onTapDown: (d) => _emit(d.localPosition.dx, w),
            onTapUp: (_) => _emit(null, w),
            child: CustomPaint(
              size: Size(w, 140),
              painter: _ProfilePainter(
                profile: widget.profile,
                scrubX: _scrubX,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.profile,
    required this.scrubX,
    required this.textColor,
  });

  final List<ProfilePoint> profile;
  final double? scrubX;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Downsample to the pixel width so 5,000 points do not jank.
    final pts = _downsample(profile, size.width.floor().clamp(2, 4096));
    var minE = pts.first.elevM, maxE = pts.first.elevM;
    for (final p in pts) {
      if (p.elevM < minE) minE = p.elevM;
      if (p.elevM > maxE) maxE = p.elevM;
    }
    final totalD = pts.last.distanceM == 0 ? 1.0 : pts.last.distanceM;
    final range = (maxE - minE).abs() < 1 ? 1.0 : maxE - minE;

    double xOf(double d) => d / totalD * size.width;
    double yOf(double e) =>
        size.height - 8 - (e - minE) / range * (size.height - 24);

    // Colored line segments by grade, with a soft filled area under each.
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final dd = b.distanceM - a.distanceM;
      final grade = dd > 0 ? (b.elevM - a.elevM).abs() / dd : 0.0;
      final color = grade > 0.15
          ? AppColors.fire
          : grade > 0.08
              ? AppColors.smoke
              : AppColors.aqiGood;
      final x0 = xOf(a.distanceM), x1 = xOf(b.distanceM);
      final y0 = yOf(a.elevM), y1 = yOf(b.elevM);
      final fill = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, y1)
        ..lineTo(x1, size.height)
        ..lineTo(x0, size.height)
        ..close();
      canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.16));
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
    }

    _label(canvas, size, '${maxE.round()} m', yOf(maxE), true);
    _label(canvas, size, '${minE.round()} m', yOf(minE), false);

    if (scrubX != null) {
      final x = scrubX!.clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppColors.larch
          ..strokeWidth = 1.5,
      );
    }
  }

  void _label(Canvas canvas, Size size, String text, double y, bool top) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, Offset(4, (y - (top ? 12 : -2)).clamp(0, size.height - 12)));
  }

  static List<ProfilePoint> _downsample(List<ProfilePoint> src, int target) {
    if (src.length <= target) return src;
    final step = src.length / target;
    return [
      for (var i = 0; i < target; i++) src[(i * step).floor()],
      src.last,
    ];
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.profile != profile || old.scrubX != scrubX;
}
