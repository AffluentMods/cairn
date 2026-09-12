// SPDX-License-Identifier: GPL-3.0-or-later
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
}) async {
  const size = 44;
  for (final entry in _iconColors(accent, track).entries) {
    try {
      final bytes = await _dotPng(entry.value, size);
      await controller.addImage(entry.key, bytes);
    } catch (_) {
      // Non-fatal: the map still works without this one icon.
    }
  }
  // Direction chevrons along the active route (the `route-arrows` symbol
  // layer in every style, z14 and up): ink on the gold line, white-edged so
  // they read on any base map.
  try {
    await controller.addImage('route-arrow', await _chevronPng(36));
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
Future<Uint8List> _chevronPng(int size) async {
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
      ..color = AppColors.inkDeep
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

Future<Uint8List> _dotPng(Color color, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 4;

  // White outline for contrast on any basemap, then the colored fill.
  canvas.drawCircle(
    center,
    radius + 2,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
  // A small darker core so overlapping dots stay legible.
  canvas.drawCircle(
    center,
    radius * 0.34,
    Paint()..color = Colors.white.withValues(alpha: 0.85),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
