// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:xml/xml.dart';

/// One incident in the InciWeb feed. The title is "{UNIT} {Name}", for
/// example "WAGPF Backbone Fire"; the link is the incident page.
class InciwebEntry {
  const InciwebEntry({required this.title, required this.url});
  final String title;
  final Uri url;
}

/// InciWeb has no JSON API (spec Section 5.4), but its RSS feed lists every
/// current incident with a link. Matching a WFIGS fire against it opens the
/// incident's own page instead of the InciWeb home page. The feed is fetched
/// on demand (a tap on "Open on InciWeb") and kept for an hour.
class InciwebSource {
  InciwebSource(this._dio);
  final Dio _dio;

  static final feedUrl =
      Uri.parse('https://inciweb.wildfire.gov/incidents/rss.xml');
  static final homeUrl = Uri.parse('https://inciweb.wildfire.gov/');
  static const _ttl = Duration(hours: 1);

  List<InciwebEntry>? _entries;
  DateTime? _fetchedAt;

  Future<List<InciwebEntry>> entries() async {
    final cached = _entries;
    final at = _fetchedAt;
    if (cached != null && at != null && DateTime.now().difference(at) < _ttl) {
      return cached;
    }
    try {
      final res = await _dio.getUri<String>(
        feedUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final body = res.data;
      if (res.statusCode == 200 && body != null && body.isNotEmpty) {
        // The feed runs to a few megabytes; parse it off the UI isolate.
        final parsed = await compute(parseInciwebFeed, body);
        if (parsed.isNotEmpty) {
          _entries = parsed;
          _fetchedAt = DateTime.now();
          return parsed;
        }
      }
    } on DioException {
      // Offline or InciWeb down: fall through to whatever we had.
    }
    return cached ?? const [];
  }

  /// The InciWeb page for a WFIGS incident, or the home page when the feed
  /// does not list it (a fire without an InciWeb entry, or no connection).
  Future<Uri> incidentUrl({required String name, String? unitId}) async {
    final hit = matchInciweb(await entries(), name: name, unitId: unitId);
    return hit?.url ?? homeUrl;
  }
}

/// Parses the RSS feed into entries. Malformed XML yields an empty list.
List<InciwebEntry> parseInciwebFeed(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    return const [];
  }
  final out = <InciwebEntry>[];
  for (final item in doc.findAllElements('item')) {
    final title = item.getElement('title')?.innerText.trim() ?? '';
    final link = item.getElement('link')?.innerText.trim() ?? '';
    if (title.isEmpty || link.isEmpty) continue;
    final uri = Uri.tryParse(link);
    if (uri == null || uri.host.isEmpty) continue;
    // The feed links with http; the site serves https.
    out.add(InciwebEntry(
      title: title,
      url: uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri,
    ));
  }
  return out;
}

final _unitToken = RegExp(r'^[A-Z]{2}[A-Z0-9]{2,5}$');

/// Finds the feed entry for a WFIGS incident [name] (for example "Backbone",
/// which InciWeb titles "WAGPF Backbone Fire"). A [unitId] (WFIGS
/// POOProtectingUnit, "WAGPF") breaks ties between same-named fires in
/// different units; without one the first name match wins.
InciwebEntry? matchInciweb(
  List<InciwebEntry> entries, {
  required String name,
  String? unitId,
}) {
  final want = normalizeIncidentName(name);
  if (want.isEmpty) return null;
  final unit = unitId?.trim().toUpperCase();
  InciwebEntry? byName;
  for (final e in entries) {
    final parts = e.title.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) continue;
    final first = parts.first;
    final hasUnit = parts.length > 1 && _unitToken.hasMatch(first);
    final titleName =
        normalizeIncidentName(hasUnit ? parts.skip(1).join(' ') : e.title);
    if (titleName != want) continue;
    if (unit != null && unit.isNotEmpty && hasUnit && first == unit) return e;
    byName ??= e;
  }
  return byName;
}

/// Lowercases, drops punctuation, a leading year, and the words "fire",
/// "wildfire" and "rx", so "2026 Moonshine Fire" and "Moonshine" agree.
String normalizeIncidentName(String s) {
  var t = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');
  t = t.replaceFirst(RegExp(r'^\s*(19|20)\d{2}\s+'), ' ');
  t = t.replaceAll(RegExp(r'\b(fire|wildfire|rx)\b'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}
