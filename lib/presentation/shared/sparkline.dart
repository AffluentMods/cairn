// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// A tiny line chart with a faint fill under it (spec Phase 4 library rows,
/// Phase 7 AQI). Draws nothing for fewer than two values.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    this.width = 72,
    this.height = 22,
    this.color,
    this.strokeWidth = 1.5,
    super.key,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(values, c, strokeWidth),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, this.color, this.strokeWidth);

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo;
    final pad = strokeWidth;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final x = pad + w * i / (values.length - 1);
      final t = span == 0 ? 0.5 : (values[i] - lo) / span;
      final y = pad + h * (1 - t);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    final fill = Path.from(line)
      ..lineTo(pad + w, size.height)
      ..lineTo(pad, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.16));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

/// Evenly picks at most [max] entries from [values] for a sparkline.
List<double> downsampleForSparkline(List<double> values, {int max = 48}) {
  if (values.length <= max) return values;
  final out = <double>[];
  for (var i = 0; i < max; i++) {
    out.add(values[(i * (values.length - 1) / (max - 1)).round()]);
  }
  return out;
}
