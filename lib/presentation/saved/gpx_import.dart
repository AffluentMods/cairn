// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/gpx/gpx_codec.dart';
import '../../l10n/app_localizations.dart';
import 'library_providers.dart';

/// The GPX size cap (spec Section 9.5): anything larger is refused before
/// parsing.
const maxGpxBytes = 20 * 1024 * 1024;

/// Imports GPX [bytes] into the library and reports through [messenger]:
/// shared by the Import GPX button and "Open with Cairn" (spec Phase 4).
/// Returns true when at least one route, track or pin was saved.
Future<bool> importGpxBytes(
  WidgetRef ref, {
  required Uint8List bytes,
  required String name,
  required AppLocalizations l10n,
  required ScaffoldMessengerState? messenger,
}) async {
  void say(String text) =>
      messenger?.showSnackBar(SnackBar(content: Text(text)));
  try {
    if (bytes.length > maxGpxBytes) {
      say(l10n.gpxImportFailed);
      return false;
    }
    final xml = utf8.decode(bytes, allowMalformed: true);
    final data = parseGpx(xml);
    if (data.isEmpty) {
      say(l10n.gpxImportFailed);
      return false;
    }
    final summary =
        await ref.read(gpxImporterProvider).import(data, fallbackName: name);
    bumpLibrary(ref);
    if (summary.waypoints == 0) {
      say(l10n.gpxImported(summary.total));
    } else if (summary.total == 0) {
      say(l10n.gpxImportedPinsOnly(summary.waypoints));
    } else {
      say(l10n.gpxImportedPins(summary.total, summary.waypoints));
    }
    return summary.total + summary.waypoints > 0;
  } on FormatException {
    say(l10n.gpxImportFailed);
    return false;
  } catch (_) {
    say(l10n.gpxImportFailed);
    return false;
  }
}
