// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/material.dart';

import 'cairn_theme.dart';

/// Prefix for a shareable theme code (Fix Pass 1 X4.4).
const cairnThemeCodePrefix = 'cairn-theme-1:';

/// Formats a color as `#RRGGBB` (alpha is always opaque for themes).
String hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Parses `#RGB`, `#RRGGBB`, or `#AARRGGBB` (with or without the `#`). Throws
/// [FormatException] on anything else.
Color parseHexColor(String input) {
  var h = input.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) throw FormatException('bad color: $input');
  final v = int.tryParse(h, radix: 16);
  if (v == null) throw FormatException('bad color: $input');
  return Color(v);
}

/// A theme as a plain JSON map (the `.cairntheme` file body).
Map<String, dynamic> themeToJson(CairnThemeSpec s) => {
      'v': 1,
      'name': s.name,
      'dark': s.isDark,
      'accent': hexOf(s.accent),
      'background': hexOf(s.background),
      'surface': hexOf(s.surface),
      'raised': hexOf(s.raised),
      'outline': hexOf(s.outline),
      'textPrimary': hexOf(s.textPrimary),
      'textSecondary': hexOf(s.textSecondary),
      'route': hexOf(s.route),
      'track': hexOf(s.track),
    };

/// Parses a theme from JSON with [id], validating the schema. Throws
/// [FormatException] on a missing or malformed field.
CairnThemeSpec themeFromJson(Map<String, dynamic> j, {required String id}) {
  final name = j['name'];
  if (name is! String || name.trim().isEmpty) {
    throw const FormatException('theme has no name');
  }
  Color col(String key) {
    final v = j[key];
    if (v is! String) throw FormatException('theme is missing color: $key');
    return parseHexColor(v);
  }

  return CairnThemeSpec(
    id: id,
    name: name.trim(),
    brightness: j['dark'] == true ? Brightness.dark : Brightness.light,
    accent: col('accent'),
    background: col('background'),
    surface: col('surface'),
    raised: col('raised'),
    outline: col('outline'),
    textPrimary: col('textPrimary'),
    textSecondary: col('textSecondary'),
    route: col('route'),
    track: col('track'),
  );
}

/// The pretty `.cairntheme` file body for [s].
String themeToFile(CairnThemeSpec s) =>
    const JsonEncoder.withIndent('  ').convert(themeToJson(s));

/// A compact, shareable `cairn-theme-1:` code for [s].
String themeToCode(CairnThemeSpec s) =>
    cairnThemeCodePrefix +
    base64Url.encode(utf8.encode(jsonEncode(themeToJson(s))));

/// Parses a `.cairntheme` file body or a `cairn-theme-1:` code into a spec with
/// [id]. Throws [FormatException] if it is neither or the schema is wrong.
CairnThemeSpec themeFromImport(String input, {required String id}) {
  final t = input.trim();
  if (t.startsWith(cairnThemeCodePrefix)) {
    final body = t.substring(cairnThemeCodePrefix.length).trim();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(base64Url.decode(body)))
          as Map<String, dynamic>;
    } on Object {
      throw const FormatException('not a valid theme code');
    }
    return themeFromJson(json, id: id);
  }
  // Otherwise treat it as a .cairntheme JSON body.
  final Object decoded;
  try {
    decoded = jsonDecode(t) as Object;
  } on FormatException {
    throw const FormatException('not a theme file or code');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('not a theme file');
  }
  return themeFromJson(decoded, id: id);
}
