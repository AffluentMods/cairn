// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/theme/app_colors.dart';

/// The POI marker colors that are map semantics (water, peak, closures, fire)
/// and stay fixed. The trailhead and viewpoint dots take the theme accent and
/// track so they match the active theme (Fix Pass 1 X4.1).
Map<String, Color> _iconColors(Color accent, Color track) => {
      'water': AppColors.water,
      'peak': AppColors.trailOsm,
      'saddle': AppColors.trailInformal,
      'camp': AppColors.aqiGood,
      'hut': AppColors.aqiGood,
      'viewpoint': track,
      'toilets': AppColors.closure,
      'parking': AppColors.closure,
      'trailhead': accent,
      'fire': AppColors.fire,
    };

/// Registers every Cairn map icon. Call after each style load (icons are cleared
/// when the style reloads). Best effort: a failure just means dots do not show.
/// [accent] and [track] color the trailhead and viewpoint dots so they follow
/// the active theme.
Future<void> addCairnIcons(
  MapLibreMapController controller, {
  required Color accent,
  required Color track,
  required Color routeInk,
}) async {
  const size = 56;
  for (final entry in _iconColors(accent, track).entries) {
    try {
      final bytes = await _poiPng(entry.key, entry.value, size);
      await controller.addImage(entry.key, bytes);
    } catch (_) {
      // Non-fatal: the map still works without this one icon.
    }
  }
  // Direction chevrons along the active route (the `route-arrows` symbol
  // layer in every style, z14 and up): [routeInk] on the route line (the
  // theme's contrast for its route color), white-edged so they read on any
  // base map.
  try {
    await controller.addImage('route-arrow', await _chevronPng(36, routeInk));
  } catch (_) {
    // Non-fatal.
  }
}

/// A numbered route waypoint marker: a [fill] disc with a dark rim and the
/// number in [ink]. Drawn as an image because MapLibre Native refuses the
/// annotation manager's data-driven `text-font`, so symbol text never shows
/// on Android, and a raster base map has no glyphs to draw text with anyway.
Future<Uint8List> waypointIconPng(
  int number, {
  required Color fill,
  required Color ink,
  int size = 56,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  final center = Offset(s / 2, s / 2);
  canvas.drawCircle(center, s / 2 - 2, Paint()..color = ink);
  canvas.drawCircle(center, s / 2 - 6, Paint()..color = fill);
  final painter = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(
        color: ink,
        fontSize: number >= 10 ? s * 0.38 : s * 0.46,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// A right-pointing chevron (the line's direction is 0 degrees for a symbol
/// placed along it), with a light outline.
Future<Uint8List> _chevronPng(int size, Color ink) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  final path = Path()
    ..moveTo(s * 0.32, s * 0.22)
    ..lineTo(s * 0.62, s * 0.50)
    ..lineTo(s * 0.32, s * 0.78);
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// A POI marker: a white-rimmed disc in the kind's color with a simple white
/// glyph that says what it is at a glance (spec Phase 2 "icons with labels"):
/// a drop for water, a peak for summits, a tent for camps, a hut, a flag for
/// trailheads, a fan for viewpoints, a flame for fires, and letters for the
/// two amenities. Drawn here so every base map, raster ones included, gets
/// the same set without a sprite sheet.
Future<Uint8List> _poiPng(String kind, Color color, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  final c = Offset(s / 2, s / 2);
  final radius = s / 2 - 4;

  canvas.drawCircle(c, radius + 2, Paint()..color = Colors.white);
  canvas.drawCircle(c, radius, Paint()..color = color);

  final glyph = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.07
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final u = s / 2; // one unit is half the icon
  Offset p(double x, double y) => Offset(c.dx + x * u, c.dy + y * u);

  switch (kind) {
    case 'water':
      final drop = Path()
        ..moveTo(p(0, -0.52).dx, p(0, -0.52).dy)
        ..quadraticBezierTo(p(0.5, 0.05).dx, p(0.5, 0.05).dy, p(0.34, 0.28).dx,
            p(0.34, 0.28).dy)
        ..arcToPoint(p(-0.34, 0.28), radius: Radius.circular(0.36 * u))
        ..quadraticBezierTo(
            p(-0.5, 0.05).dx, p(-0.5, 0.05).dy, p(0, -0.52).dx, p(0, -0.52).dy)
        ..close();
      canvas.drawPath(drop, glyph);
    case 'peak':
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.5, 0.36).dx, p(-0.5, 0.36).dy)
          ..lineTo(p(0, -0.46).dx, p(0, -0.46).dy)
          ..lineTo(p(0.5, 0.36).dx, p(0.5, 0.36).dy)
          ..close(),
        glyph,
      );
    case 'saddle':
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.52, -0.3).dx, p(-0.52, -0.3).dy)
          ..quadraticBezierTo(
              p(0, 0.55).dx, p(0, 0.55).dy, p(0.52, -0.3).dx, p(0.52, -0.3).dy),
        stroke,
      );
    case 'camp':
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.55, 0.38).dx, p(-0.55, 0.38).dy)
          ..lineTo(p(0, -0.45).dx, p(0, -0.45).dy)
          ..lineTo(p(0.55, 0.38).dx, p(0.55, 0.38).dy)
          ..close(),
        glyph,
      );
      // The door, in the disc color.
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.16, 0.38).dx, p(-0.16, 0.38).dy)
          ..lineTo(p(0, 0.05).dx, p(0, 0.05).dy)
          ..lineTo(p(0.16, 0.38).dx, p(0.16, 0.38).dy)
          ..close(),
        Paint()..color = color,
      );
    case 'hut':
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.55, -0.05).dx, p(-0.55, -0.05).dy)
          ..lineTo(p(0, -0.5).dx, p(0, -0.5).dy)
          ..lineTo(p(0.55, -0.05).dx, p(0.55, -0.05).dy)
          ..close(),
        glyph,
      );
      canvas.drawRect(Rect.fromPoints(p(-0.38, -0.05), p(0.38, 0.42)), glyph);
    case 'trailhead':
      canvas.drawLine(p(-0.25, -0.5), p(-0.25, 0.48), stroke);
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.22, -0.5).dx, p(-0.22, -0.5).dy)
          ..lineTo(p(0.42, -0.25).dx, p(0.42, -0.25).dy)
          ..lineTo(p(-0.22, 0.0).dx, p(-0.22, 0.0).dy)
          ..close(),
        glyph,
      );
    case 'viewpoint':
      // A fan of sight lines from a point, the classic viewpoint mark.
      for (final a in [-0.45, -0.22, 0.0, 0.22, 0.45]) {
        canvas.drawLine(
          p(0, 0.4),
          p(math.sin(a * 1.4) * 0.55, 0.4 - math.cos(a * 1.4) * 0.85),
          stroke,
        );
      }
    case 'fire':
      final flame = Path()
        ..moveTo(p(0, -0.55).dx, p(0, -0.55).dy)
        ..cubicTo(p(0.55, -0.1).dx, p(0.55, -0.1).dy, p(0.5, 0.35).dx,
            p(0.5, 0.35).dy, p(0, 0.5).dx, p(0, 0.5).dy)
        ..cubicTo(p(-0.5, 0.35).dx, p(-0.5, 0.35).dy, p(-0.4, 0).dx,
            p(-0.4, 0).dy, p(-0.12, -0.2).dx, p(-0.12, -0.2).dy)
        ..cubicTo(p(-0.05, -0.05).dx, p(-0.05, -0.05).dy, p(0.15, -0.15).dx,
            p(0.15, -0.15).dy, p(0, -0.55).dx, p(0, -0.55).dy)
        ..close();
      canvas.drawPath(flame, glyph);
    case 'parking':
      _glyphText(canvas, 'P', c, s * 0.62);
    case 'toilets':
      _glyphText(canvas, 'WC', c, s * 0.36);
    default:
      canvas.drawCircle(c, radius * 0.34, glyph);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void _glyphText(Canvas canvas, String text, Offset center, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}
