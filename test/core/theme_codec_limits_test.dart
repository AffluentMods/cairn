// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/core/theme/cairn_theme.dart';
import 'package:cairn/core/theme/theme_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an oversized import payload is refused before decoding', () {
    final huge = '{"name":"x"${',"a":1' * 20000}}'; // well over 64 KB
    expect(huge.length, greaterThan(maxThemeImportChars));
    expect(() => themeFromImport(huge, id: 'z'), throwsFormatException);
  });

  test('a long theme name is capped on import', () {
    final spec = builtInThemeById('larch')!;
    final json = themeToJson(spec)..['name'] = 'n' * 500;
    final back = themeFromJson(json, id: 'z');
    expect(back.name.length, maxThemeNameLength);
  });

  test('a normal payload still imports', () {
    final spec = builtInThemeById('paper')!;
    final back = themeFromImport(themeToCode(spec), id: 'z');
    expect(back.name, 'Paper');
  });
}
