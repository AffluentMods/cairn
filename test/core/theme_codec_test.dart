// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/theme/cairn_theme.dart';
import 'package:cairn/core/theme/theme_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final spec = builtInThemeById('basalt')!;

  void expectSame(CairnThemeSpec a, CairnThemeSpec b) {
    expect(a.isDark, b.isDark);
    expect(a.accent.toARGB32(), b.accent.toARGB32());
    expect(a.background.toARGB32(), b.background.toARGB32());
    expect(a.surface.toARGB32(), b.surface.toARGB32());
    expect(a.raised.toARGB32(), b.raised.toARGB32());
    expect(a.outline.toARGB32(), b.outline.toARGB32());
    expect(a.textPrimary.toARGB32(), b.textPrimary.toARGB32());
    expect(a.textSecondary.toARGB32(), b.textSecondary.toARGB32());
    expect(a.route.toARGB32(), b.route.toARGB32());
    expect(a.track.toARGB32(), b.track.toARGB32());
  }

  test('file body round-trips', () {
    final back = themeFromImport(themeToFile(spec), id: 'x');
    expect(back.name, spec.name);
    expectSame(back, spec);
  });

  test('share code round-trips and is prefixed', () {
    final code = themeToCode(spec);
    expect(code.startsWith(cairnThemeCodePrefix), isTrue);
    expectSame(themeFromImport(code, id: 'y'), spec);
  });

  test('hex helpers are inverse', () {
    expect(hexOf(const Color(0xFF112233)), '#112233');
    expect(parseHexColor('#abc').toARGB32(), 0xFFAABBCC);
    expect(parseHexColor('D9A441').toARGB32(), 0xFFD9A441);
  });

  test('garbage and bad codes throw FormatException', () {
    expect(() => themeFromImport('garbage', id: 'z'), throwsFormatException);
    expect(() => themeFromImport('cairn-theme-1:not base64!!', id: 'z'),
        throwsFormatException);
    expect(() => themeFromJson({'name': 'x'}, id: 'z'), throwsFormatException);
    expect(() => themeFromJson({'accent': '#fff'}, id: 'z'),
        throwsFormatException); // no name
  });
}
