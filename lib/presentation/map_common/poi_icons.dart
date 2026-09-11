// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/theme/app_colors.dart';

/// The icons registered with the map at style load, keyed by the name the POI
/// and fire layers reference via `icon-image`. We generate simple colored dots
/// at runtime (spec Section 8 fallback: controller.addImage) so no sprite sheet
/// needs to ship, which keeps the APK small and F-Droid clean.
const _iconColors = <String, Color>{
  'water': AppColors.water,
  'peak': AppColors.trailOsm,
  'saddle': AppColors.trailInformal,
  'camp': AppColors.aqiGood,
  'hut': AppColors.aqiGood,
  'viewpoint': AppColors.glacier,
  'toilets': AppColors.closure,
  'parking': AppColors.closure,
  'trailhead': AppColors.larch,
  'fire': AppColors.fire,
};

/// Registers every Cairn map icon. Call after each style load (icons are cleared
/// when the style reloads). Best effort: a failure just means dots do not show.
Future<void> addCairnIcons(MapLibreMapController controller) async {
  const size = 44;
  for (final entry in _iconColors.entries) {
    try {
      final bytes = await _dotPng(entry.value, size);
      await controller.addImage(entry.key, bytes);
    } catch (_) {
      // Non-fatal: the map still works without this one icon.
    }
  }
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
